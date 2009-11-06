class Martsearch
  attr_reader :config, :search_data, :search_results
  attr_accessor :http_client, :index, :datasets, :datasets_by_name
  
  def initialize( config_file_name )
    @http_client = Net::HTTP
    if ENV['http_proxy']
      proxy = URI.parse( ENV['http_proxy'] )
      @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    config_file = File.new( config_file_name, "r" )
    @config     = JSON.load(config_file)
    
    @index = Index.new( @config["index"], @http_client ) # The index object
    
    @datasets = []
    @config["datasets"].each do |ds|
      ds_conf_file = File.new("#{Dir.pwd}/config/datasets/#{ds}/config.json","r")
      ds_conf      = JSON.load(ds_conf_file)
      dataset      = Dataset.new( ds_conf )
      
      if dataset.custom_sort
        # If we have a custom sorting routine, use a Mock object
        # to override the sorting method.
        dataset = Mock.method( dataset, :sort_results ) { eval( dataset.custom_sort ) }
      end
      
      @datasets.push( dataset )
    end
    
    @datasets_by_name = {}
    @datasets.each do |ds|
      @datasets_by_name[ds.dataset_name] = ds
    end
    
    # Error Message Stash...
    @error_messages = []
    
    # Stores for current search result data
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
    search_data = {}
    
    begin
      search_data = @index.search( query, page )
    rescue IndexSearchError => e
      # FIXME: Add a way to test/report this index search error
    end
    
    if @index.current_results_total === 0
      search_data = nil
    else
      threads = []

      @datasets.each do |ds|
        if ds.use_in_search
          threads << Thread.new(ds) do |dataset|
            search_terms = @index.grouped_terms[ dataset.joined_index_field ]
            
            begin
              mart_results = dataset.search( search_terms, @index.current_results )
              dataset.add_to_results_stash( search_data, mart_results )
            rescue Biomart::BiomartError => e
              # FIXME: Add a way to test/report this biomart search error
            end
          end
        end
      end

      threads.each { |thread| thread.join }
    end
    
    # Store the search data...
    @search_data    = search_data
    @search_results = []
    
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
  
end