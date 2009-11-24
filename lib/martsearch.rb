class Martsearch
  attr_reader :config, :search_data, :search_results, :portal_name, :cache
  attr_accessor :http_client, :index, :datasets, :datasets_by_name, :errors
  
  def initialize( config_desc )
    @http_client = Net::HTTP
    if ENV['http_proxy']
      proxy = URI.parse( ENV['http_proxy'] )
      @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    @config = nil
    if config_desc.is_a?(String)
      @config = JSON.load( File.new( config_desc, "r" ) )
    else
      @config = config_desc
    end
    
    @portal_name = @config["portal_name"]
    @index       = Index.new( @config["index"], @http_client ) # The index object
    
    if @config["cache"] && @config["cache"].is_a?(Hash)
      @cache = initialize_cache( @config["cache"]["type"] )
    else
      @cache = initialize_cache()
    end
    
    @datasets         = []
    @datasets_by_name = {}
    @config["datasets"].each do |ds|
      ds_conf = JSON.load( File.new("#{Dir.pwd}/config/datasets/#{ds}/config.json","r") )
      dataset = Dataset.new( ds_conf )
      
      if dataset.custom_sort
        # If we have a custom sorting routine, use a Mock object
        # to override the sorting method.
        dataset = Mock.method( dataset, :sort_results ) { eval( dataset.custom_sort ) }
      end
      
      @datasets.push( dataset )
      @datasets_by_name[ dataset.dataset_name.to_sym ] = dataset
    end
    
    # Stores for search result data and errors...
    @errors         = []
    @search_data    = {}
    @search_results = []
  end
  
  # Function to perform the searches against the index and marts.
  #
  # Stores a results stash holding the data in a structure like...
  # {
  #   IndexDocUniqueKey => {
  #     "index"        => {}, # index results for this doc
  #     "dataset_name" => []/{}, # array/hash of sorted biomart data
  #     "dataset_name" => []/{}, # array/hash of sorted biomart data
  #   }
  # }
  # 
  # But returns an ordered list of the search results (primary index field)
  def search( query, page )
    @search_data    = {}
    @search_results = []
    
    begin
      @search_data = @index.search( query, page )
    rescue IndexSearchError => error
      @errors.push({
        :highlight => "The search term you used has caused an error on the search engine, please try another search term without any special characters in it.",
        :full_text => error
      })
    end
    
    if @index.current_results_total === 0
      @search_data = nil
    else
      threads = []
      
      @datasets.each do |ds|
        if ds.use_in_search
          threads << Thread.new(ds) do |dataset|
            begin
              search_terms = @index.grouped_terms[ dataset.joined_index_field ]
              mart_results = dataset.search( search_terms )
              dataset.add_to_results_stash( @search_data, mart_results )
            rescue Biomart::BiomartError => error
              @errors.push({
                :highlight => "The '#{dataset.display_name}' dataset has returned an error for this query.  Please try submitting your search again.",
                :full_text => error
              })
            end
          end
        end
      end
      
      threads.each { |thread| thread.join }
    end
    
    if @index.ordered_results.size > 0
      @search_results = paged_results()
    end
    
    # Return paged_results
    return @search_results
  end
  
  # Simple utility function - returns a paginated (using will_paginate) 
  # list of the search results (the index primary key).
  def paged_results
    results = WillPaginate::Collection.create( @index.current_page, @index.docs_per_page, @index.current_results_total ) do |pager|
       pager.replace(@index.ordered_results)
    end
    return results
  end
  
  # Utility function to return all of the custom stylesheets for the 
  # datasets as one concatenated file.
  def dataset_stylesheets
    stylesheet = ""
    
    @datasets.each do |ds|
      if ds.use_in_search and ds.stylesheet
        stylesheet << "\n" + ds.stylesheet
      end
    end
    
    return stylesheet
  end
  
  # Utility function to return all of the custom javascript files for 
  # the datasets as one concatenated file.
  def dataset_javascripts
    js = ""
    
    @datasets.each do |ds|
      if ds.use_in_search and ds.javascript
        js << "\n" + ds.javascript
      end
    end
    
    return js
  end
  
  # Utility function to send an email to/from an address specified in the 
  # config file.  Uses Pony (http://github.com/benprew/pony) to handle the 
  # email delivery.
  def send_email( options={} )
    pony_opts = {
      :to      => self.config["email"]["to"],
      :from    => self.config["email"]["from"],
      :subject => "A Message from MartSearch...",
      :body    => "You have been sent this message from your MartSearch portal."
    }

    if self.config["email"]["smtp"]
      pony_opts[:via]  = :smtp
      pony_opts[:smtp] = {}
      [:host, :port, :user, :pass, :auth, :domain].each do |opt|
        if self.config["email"]["smtp"][opt.to_s]
          pony_opts[:smtp][opt] = self.config["email"]["smtp"][opt.to_s]
        end
      end
    else
      pony_opts[:via] = :sendmail
    end

    Pony.mail( pony_opts.merge(options) )
  end
  
  private
  
  # Helper function to initialize the caching system.  Uses 
  # ActiveSupport::Cache so that we can easily support multiple 
  # cache backends.
  def initialize_cache( type=nil )
    case type
    when /memcache/
      servers = ["localhost"]
      opts = { :namespace => "martsearch", :no_reply => true }
      
      if self.config["cache"]["servers"]
        servers = self.config["cache"]["servers"]
      end
      
      if self.config["cache"]["namespace"]
        opts[:namespace] = self.config["cache"]["namespace"]
      end
      
      return ActiveSupport::Cache::MemCacheStore.new( servers, opts )
    when /file/
      file_store = "#{Dir.pwd}/tmp/cache"
      if self.config["cache"]["file_store"]
        file_store = self.config["cache"]["file_store"]
      end
      return ActiveSupport::Cache::FileStore.new( file_store )
    else
      return ActiveSupport::Cache::MemoryStore.new()
    end
  end
end