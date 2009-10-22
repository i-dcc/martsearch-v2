class Dataset
  attr_reader :dataset, :display_name, :dataset_name, :joined_index_field, :joined_biomart_filter, :joined_biomart_attribute
  attr_accessor :url, :attributes, :filters
  
  def initialize( conf, client )
    
    @url                      = conf["url"]
    @dataset_name             = conf["dataset_name"]
    @display_name             = conf["display_name"]
    
    @joined_index_field       = conf["searching"]["joined_index_field"]
    @joined_biomart_filter    = conf["searching"]["joined_biomart_filter"]
    @joined_biomart_attribute = conf["searching"]["joined_biomart_attribute"]
    @filters                  = conf["searching"]["filters"]
    @attributes               = conf["searching"]["attributes"]
    
    # Connection client...
    @http_client = client
    
    @dataset = nil
    reload_dataset
    
  end
  
  # Simple heartbeat function - checks that the biomart 
  # server/dataset is alive/online.  Returns true/false.
  def is_alive?
    @dataset.alive?
  end
  
  # Simple utility function to force reload the Biomart::Dataset
  # object that this class uses.
  def reload_dataset
    @dataset = Biomart::Dataset.new( @url, { :name => @dataset_name } )
  end
  
  # 
  def search( query, index_docs )
    
    search_params  = {
      :attributes      => [],
      :filters         => { @joined_biomart_filter => query.join(",") },
      :process_results => true
    }
    
    @filters.each do |name,value|
      search_params[:filters][name] = value
    end
    
    @attributes.each do |attribute|
      search_params[:attributes].push(attribute)
    end
    
    # TODO: Need to handle Biomart::BiomartError's here!!!
    search_results = @dataset.search( search_params )
    sorted_results = sort_results( search_results )
    
    return sorted_results
  end
  
  # Sorting function for the biomart results.  Returns a hash, 
  # keyed by the 'joined_biomart_attribute' where the values are 
  # an array of biomart results associated with this key.
  #
  # i.e.
  # {
  #   'Cbx1' => [ biomart return for Cbx1 ],
  #   'Cbx2' => [ biomart return for Cbx2 ]
  # }
  def sort_results( search_results )
    sorted_results = {}
    search_results.each do |result|
      unless sorted_results[ result[ @joined_biomart_attribute ] ]
        sorted_results[ result[ @joined_biomart_attribute ] ] = []
      end
      
      sorted_results[ result[ @joined_biomart_attribute ] ].push( result )
    end
    
    return sorted_results
  end
  
end