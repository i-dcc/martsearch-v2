# This class is responsible for the set-up, building and updating 
# of a Solr search index for use with a MartSearchr application.
class IndexBuilder
  attr_reader :martsearch, :index_conf
  
  def initialize( config_desc )
    @http_client = Net::HTTP
    if ENV['http_proxy']
      proxy = URI.parse( ENV['http_proxy'] )
      @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end
    
    @martsearch = Martsearch.new(config_desc)
    
    @index_conf = @martsearch.config["index"]
    @index_conf["datasets"] = dataset_index_conf()
  end
  
  # Function to create the Solr XML Schema used to define 
  # how our search engine is structured
  def solr_schema
    template = File.open( "#{File.dirname(__FILE__)}/schema.xml.erb", 'r' )
    erb      = ERB.new( template.read )
    schema   = erb.result( binding )
    return schema
  end
  
  
  
  private
  
  # Utility function to grab the index configuration from each of 
  # the datasets to be added into our @index_conf
  def dataset_index_conf
    dataset_conf = []
    @martsearch.datasets.each do |ds|
      dataset_conf.push( ds.config )
    end
    return dataset_conf
  end
end