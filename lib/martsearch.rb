class Martsearch
  attr_reader :config
  attr_accessor :http_client, :index, :datasources
  
  def initialize( config_file_name )
    @http_client = Net::HTTP
    if ENV['http_proxy']
      proxy = URI.parse( ENV['http_proxy'] )
      @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    config_file = File.new( config_file_name, "r" )
    @config     = JSON.load(config_file)
    
    @index = Index.new( @config["index"], @http_client ) # The index object
    
    @datasources = []
    @config["datasources"].each do |ds|
      ds_conf_file = File.new("#{Dir.pwd}/config/datasources/#{ds["config"]}","r")
      ds_conf      = JSON.load(ds_conf_file)
      datasource   = Datasource.new( ds_conf, @http_client )
      
      if ds["custom_sort"]
        # If we have a custom sorting routine, use a Mock object
        # to override the sorting method.
        file = File.new("#{Dir.pwd}/config/datasources/#{ds["custom_sort"]}","r")
        buffer = file.read
        file.close
        datasource = Mock.method( datasource, :sort_results ) { eval(buffer) }
      end
      
      @datasources.push( datasource )
    end
  end
  
  # Function to perform the searches against the index and marts.
  #
  # Returns a results stash holding the data in a structure like...
  # {
  #   IndexDocUniqueKey => {
  #     "index"        => {}, # index results for this doc
  #     "datasource_name" => []/{}, # array/hash of sorted biomart data
  #     "datasource_name" => []/{}, # array/hash of sorted biomart data
  #   }
  # }
  def search( query, page )
    results = @@ms.index.search( query, page )
    
    threads = []
    
    @@ms.datasources.each do |ds|
      if ds.use_in_search
        threads << Thread.new(ds) do |datasource|
          search_terms = @@ms.index.grouped_terms[ datasource.joined_index_field ]
          mart_results = datasource.search( search_terms, @@ms.index.current_results )
          datasource.add_to_results_stash( results, mart_results )
        end
      end
    end
    
    threads.each { |thread| thread.join }
    
    return results
  end
  
  
end