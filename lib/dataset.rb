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
    
    @dataset = nil
    reload_dataset
    
  end
  
  def is_alive?
    @dataset.alive?
  end
  
  def reload_dataset
    @dataset = Biomart::Dataset.new( @url, { :name => @dataset_name } )
  end
  
  
end