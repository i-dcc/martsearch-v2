class Dataset
  attr_reader :dataset, :dataset_name, :use_in_search, :stylesheet, :custom_sort
  attr_reader :joined_index_field, :joined_biomart_filter, :joined_biomart_attribute
  
  attr_accessor :url, :attributes, :filters, :display_name
  
  def initialize( conf )
    
    @url                      = conf["url"]
    @dataset_name             = conf["dataset_name"]
    @display_name             = conf["display_name"]
    
    @joined_index_field       = conf["searching"]["joined_index_field"]
    @joined_biomart_filter    = conf["searching"]["joined_biomart_filter"]
    @joined_biomart_attribute = conf["searching"]["joined_biomart_attribute"]
    @filters                  = conf["searching"]["filters"]
    @attributes               = conf["searching"]["attributes"]
    
    @use_in_search            = conf["use_in_search"]
    
    @dataset                  = Biomart::Dataset.new( @url, { :name => @dataset_name } )
    
    if conf["custom_sort"]
      file = File.new("#{Dir.pwd}/config/datasets/#{@dataset_name}/custom_sort.rb","r")
      @custom_sort = file.read
      file.close
    else
      @custom_sort = nil
    end
    
    if conf["custom_css"]
      file = File.new("#{Dir.pwd}/config/datasets/#{@dataset_name}/style.css","r")
      @stylesheet = file.read
      file.close
    else
      @stylesheet = nil
    end
    
    @current_search_results = nil
    @current_sorted_results = nil
    
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
    
    @current_search_results = @dataset.search( search_params )
    @current_sorted_results = sort_results()
    
    return @current_sorted_results
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
  def sort_results
    sorted_results = {}
    @current_search_results.each do |result|
      unless sorted_results[ result[ @joined_biomart_attribute ] ]
        sorted_results[ result[ @joined_biomart_attribute ] ] = []
      end
      
      sorted_results[ result[ @joined_biomart_attribute ] ].push( result )
    end
    
    return sorted_results
  end
  
  # Function to add the biomart results into the results_stash - 
  # a cache of all the returned search data used to render a page.
  def add_to_results_stash( stash, biomart_results )
    
    # First, see if the primary key of the index is the same 
    # as the primary key of our biomart_results, if yes, use 
    # this association as it's easy and bloody fast!
    do_a_recursive_lookup = true
    stash.each do |stash_key,stash_data|
      if biomart_results[stash_key]
        stash_data[@dataset_name] = biomart_results[stash_key]
        do_a_recursive_lookup = false
      end
    end
    
    # If the above was unsuccessful, looks like we have some work 
    # to do...
    if do_a_recursive_lookup
      
      # Create a lookup hash of the @joined_index_field values 
      # so that we can easily associate our biomart_results back 
      # to a primary_key...
      lookup = {}

      stash.each do |stash_key,stash_data|
        if stash_data["index"][@joined_index_field].is_a?(Array)
          stash_data["index"][@joined_index_field].each do |lookup_key|
            lookup[lookup_key] = stash_key
          end
        else
          lookup[ stash_data["index"][@joined_index_field] ] = stash_key
        end
      end
      
      biomart_results.each do |biomart_key,biomart_data|
        stash[ lookup[biomart_key] ][@dataset_name] = biomart_data
      end
      
    end
    
  end
  
  # Utility function to clean up superscript text in biomart attributes
  # will convert text between <> tags to <sup></sup>, but leave other 
  # HTML formatted text alone.
  def fix_superscript_text_in_attribute( attribute )
    if attribute.match("<.+>.+</.+>")
      # HTML code - leave alone...
    elsif attribute.match("<.+>")
      match = /(.+)<(.+)>(.*)/.match(attribute);
      attribute = match[1] + "<sup>" + match[2] + "</sup>" + match[3];
    end
    
    return attribute;
  end
  
end