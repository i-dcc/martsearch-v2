class Martsearch
  attr_reader :config
  attr_accessor :http_client, :index, :datasets
  
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
      ds_conf_file = File.new("#{Dir.pwd}/config/datasets/#{ds["name"]}/config.json","r")
      ds_conf      = JSON.load(ds_conf_file)
      dataset      = Dataset.new( ds_conf, @http_client )
      
      if ds["custom_sort"]
        # If we have a custom sorting routine, use a Mock object
        # to override the sorting method.
        file = File.new("#{Dir.pwd}/config/datasets/#{ds["name"]}/custom_sort.rb","r")
        buffer = file.read
        file.close
        dataset = Mock.method( dataset, :sort_results ) { eval(buffer) }
      end
      
      @datasets.push( dataset )
    end
  end
  
  # Function to perform the searches against the index and marts.
  #
  # Returns a results stash holding the data in a structure like...
  # {
  #   IndexDocUniqueKey => {
  #     "index"        => {}, # index results for this doc
  #     "dataset_name" => []/{}, # array/hash of sorted biomart data
  #     "dataset_name" => []/{}, # array/hash of sorted biomart data
  #   }
  # }
  def search( query, page )
    results = @index.search( query, page )
    
    # FIXME: If the index returns no data - BUG OUT!!!!
    
    threads = []
    
    @datasets.each do |ds|
      if ds.use_in_search
        threads << Thread.new(ds) do |dataset|
          search_terms = @index.grouped_terms[ dataset.joined_index_field ]
          mart_results = dataset.search( search_terms, @index.current_results )
          dataset.add_to_results_stash( results, mart_results )
        end
      end
    end
    
    threads.each { |thread| thread.join }
    
    return results
  end
  
  
end