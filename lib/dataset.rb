class Dataset
  attr_reader :display_name, :dataset_name
  attr_accessor :url
  
  def initialize( conf, client )
    
    @url          = conf["url"]
    @dataset_name = conf["dataset_name"]
    @display_name = conf["display_name"]
    
    @filters    = {}
    @attributes = []
    
    # Connection client...
    @http_client   = client
    
    #@dataset = Biomart::Dataset( conf["url"] )
    
  end
  
  
  
end