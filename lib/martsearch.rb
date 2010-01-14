class Martsearch
  attr_reader :config, :search_data, :search_results, :portal_name, :cache
  attr_accessor :http_client, :index, :datasets, :datasets_by_name, :errors
  
  def initialize( config_desc )
    @http_client = Net::HTTP
    if ENV['http_proxy'] or ENV['HTTP_PROXY']
      proxy = URI.parse( ENV['http_proxy'] ) || URI.parse( ENV['HTTP_PROXY'] )
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
    @config["datasets"].each do |ds_name|
      ds_conf = JSON.load( File.new("#{File.dirname(__FILE__)}/../config/datasets/#{ds_name}/config.json","r") )
      dataset = Dataset.new( ds_name, ds_conf )
      
      if dataset.custom_sort
        # If we have a custom sorting routine, use a Mock object
        # to override the sorting method.
        dataset = Mock.method( dataset, :sort_results ) { eval( dataset.custom_sort ) }
      end
      
      @datasets.push( dataset )
      @datasets_by_name[ dataset.internal_name.to_sym ] = dataset
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
  #     "index"         => {}, # index results for this doc
  #     "internal_name" => []/{}, # array/hash of sorted biomart data
  #     "internal_name" => []/{}, # array/hash of sorted biomart data
  #   }
  # }
  # 
  # But returns an ordered list of the search results (primary index field)
  def search( query, page )
    if page.nil?
      page = 1
    end
    
    @errors     = []
    cached_data = @cache.fetch("query:#{query}-page:#{page}")
    if cached_data
      search_from_cache( cached_data )
    else
      search_from_fresh( query, page )
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
      if ds.stylesheet
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
      if ds.javascript
        js << "\n" + ds.javascript
      end
    end
    
    return js
  end
  
  # Utility function to send an email to/from an address specified in the 
  # config file.  Uses Mail (http://github.com/mikel/mail) to handle the 
  # email formatting (and delivery if using SMTP).
  def send_email( options={} )
    mail_opts = {
      :to      => self.config["email"]["to"],
      :from    => self.config["email"]["from"],
      :subject => "A Message from MartSearch...",
      :body    => "You have been sent this message from your MartSearch portal."
    }.merge!(options)
    
    mail = Mail.new do
      from     mail_opts[:from]
      to       mail_opts[:to]
      subject  mail_opts[:subject]
      body     mail_opts[:body]
    end
    
    if self.config["email"]["smtp"]
      smtp_opts = { :host => "127.0.0.1", :port => "25" }
      
      [:host, :port, :user, :pass].each do |opt|
        if self.config["email"]["smtp"][opt.to_s]
          smtp_opts[opt] = self.config["email"]["smtp"][opt.to_s]
        end
      end
      
      Mail.defaults do
        smtp smtp_opts[:host], smtp_opts[:port]
        if smtp_opts[:user] then user smtp_opts[:user] end
        if smtp_opts[:pass] then pass smtp_opts[:pass] end
      end
      
      mail.deliver!
    else
      # Send via sendmail
      sendmail = `which sendmail`.chomp
      if sendmail.empty? then sendmail = "/usr/sbin/sendmail" end
      
      IO.popen('-', 'w+') do |pipe|
        if pipe
          pipe.write(mail.to_s)
        else
          exec(sendmail, "-t")
        end
      end
    end
  end
  
  # Utility function to tell the templates if they need to prepend 
  # anything to the link uri's for things such as images, stylesheets 
  # or javascript files
  def base_uri
    url = URI.parse( @config["portal_url"] )
    if url.path === "/"
      return ""
    else
      return url.path
    end
  end
  
  private
  
  # Utility function to extract search results from a cached data object
  def search_from_cache( cached_data )
    cached_data_obj              = JSON.parse(cached_data)
    @search_data                 = cached_data_obj["search_data"]
    @index.current_page          = cached_data_obj["current_page"]
    @index.current_results_total = cached_data_obj["current_results_total"]
    @index.ordered_results       = cached_data_obj["ordered_results"]
    
    @search_results = []
    if @index.ordered_results.size > 0
      @search_results = paged_results()
    end
  end
  
  # Utility function to perform a search off of the index and datasets
  def search_from_fresh( query, page )
    @search_data         = {}
    @search_results      = []
    do_not_save_to_cache = false
    
    begin
      @search_data = @index.search( query, page )
    rescue IndexSearchError => error
      @errors.push({
        :highlight => "The search term you used has caused an error on the search engine, please try another search term without any special characters in it.",
        :full_text => error
      })
      do_not_save_to_cache = true
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
              dataset.add_to_results_stash( @index.primary_field, @search_data, mart_results )
            rescue Biomart::BiomartError => error
              @errors.push({
                :highlight => "The '#{dataset.display_name}' dataset has returned an error for this query.  Please try submitting your search again.",
                :full_text => error
              })
              do_not_save_to_cache = true
            end
          end
        end
      end
    
      threads.each { |thread| thread.join }
    end
  
    if @index.ordered_results.size > 0
      @search_results = paged_results()
    end
    
    unless do_not_save_to_cache
      obj_to_cache = {
        :search_data           => @search_data,
        :current_page          => @index.current_page,
        :current_results_total => @index.current_results_total,
        :ordered_results       => @index.ordered_results
      }
      @cache.write( "query:#{query}-page:#{page}", obj_to_cache.to_json, :expires_in => 3.hours )
    end
  end
  
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