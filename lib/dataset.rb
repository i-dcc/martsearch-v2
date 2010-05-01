# Class for representing a biomart dataset and a defined query.  All 
# aspects of this class/dataset/query can be configured via the 
# configuration json.
class Dataset
  attr_reader :dataset, :dataset_name
  attr_reader :joined_index_field, :joined_biomart_filter, :joined_biomart_attribute
  attr_reader :use_custom_view_helpers, :use_custom_routes, :config, :internal_name
  attr_accessor :url, :attributes, :filters, :display_name, :description
  
  def initialize( internal_name, conf )
    @internal_name            = internal_name
    
    @config                   = conf
    @url                      = conf["url"]
    @dataset_name             = conf["dataset_name"]
    @display_name             = conf["display_name"]
    @description              = conf["description"]
    
    @joined_index_field       = nil
    @joined_biomart_filter    = nil
    @joined_biomart_attribute = nil
    @filters                  = nil
    @attributes               = nil
    
    if self.use_in_search?
      @joined_index_field       = conf["searching"]["joined_index_field"]
      @joined_biomart_filter    = conf["searching"]["joined_biomart_filter"]
      @joined_biomart_attribute = conf["searching"]["joined_biomart_attribute"]
      @filters                  = conf["searching"]["filters"]
      @attributes               = conf["searching"]["attributes"]
    end
    
    @dataset                  = Biomart::Dataset.new( @url, { :name => @dataset_name } )
    @use_custom_view_helpers  = conf["custom_view_helpers"]
    @use_custom_routes        = conf["custom_routes"]
    
    @current_search_results = nil
    @current_sorted_results = nil
  end
  
  # Function to return a the contents of custom css file (if configured) or nil
  def stylesheet
    load_file_if_true( @config["custom_css"], "style.css" )
  end
  
  # Function to return a the contents of custom js file (if configured) or nil
  def javascript
    load_file_if_true( @config["custom_js"], "javascript.js" )
  end
  
  # Function to return a the contents of custom sort file (if configured) or nil
  def custom_sort
    load_file_if_true( @config["custom_sort"], "custom_sort.rb" )
  end
  
  # Function to return true/false for if a dataset is to be used in 
  # the search functionallity.
  def use_in_search?
    self.config["use_in_search"] ? true : false
  end
  
  # Function to return true/false for if a dataset is to be used 
  # in the display after a search.
  def use_in_display?
    self.config["display"] ? true : false
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
  
  # Function to perform the biomart queries needed to retrieve the 
  # bulk data.  Takes an array of values to be searched against the 
  # 'joined_biomart_filter' set in the config file.  Returns the sorted 
  # and processed data.
  def search( query )
    # Don't perform a search on empty parameters - this is bad!
    if query
      search_params  = {
        :attributes      => [],
        :filters         => { @joined_biomart_filter => query.join(",") },
        :process_results => true,
        :timeout         => 20
      }
    
      @filters.each do |name,value|
        search_params[:filters][name] = value
      end
    
      @attributes.each do |attribute|
        search_params[:attributes].push(attribute)
      end
    
      @current_search_results = @dataset.search( search_params )
      @current_sorted_results = sort_results()
    else
      @current_search_results = {}
      @current_sorted_results = {}
    end
    
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
      joined_result    = result[ @joined_biomart_attribute ]
      required_attrs   = self.config["searching"]["required_attributes"]
      save_this_result = true
      
      unless required_attrs.nil?
        required_attrs.each do |req_attr|
          if result[req_attr].nil?
            save_this_result = false
          end
        end
      end
      
      if save_this_result
        unless sorted_results[ joined_result ]
          sorted_results[ joined_result ] = []
        end
        
        sorted_results[ joined_result ].push( result )
      end
    end
    
    return sorted_results
  end
  
  # Function to add the biomart results into the results_stash - 
  # a cache of all the returned search data used to render a page.
  def add_to_results_stash( index_key, stash, biomart_results )
    
    # First, see if the primary key of the index is the same 
    # as the primary key of our biomart_results, if yes, use 
    # this association as it's easy and bloody fast!
    if @joined_index_field === index_key
      
      stash.each do |stash_key,stash_data|
        stash_data[@internal_name] = biomart_results[stash_key]
      end
      
    else
      
      # Create a lookup hash of the @joined_index_field values 
      # so that we can easily associate our biomart_results back 
      # to a primary_key...
      lookup = {}

      stash.each do |stash_key,stash_data|
        joined_index_field_data = stash_data["index"][@joined_index_field]
        
        if joined_index_field_data.is_a?(Array)
          joined_index_field_data.each do |lookup_key|
            lookup[lookup_key] = stash_key
          end
        else
          lookup[joined_index_field_data] = stash_key
        end
      end
      
      biomart_results.each do |biomart_key,biomart_data|
        stash_to_append_to = stash[ lookup[biomart_key] ]
        
        if stash_to_append_to
          if @custom_sort
            # If someone uses a custom sort- we assume they're taking care
            # of grouping all of thier data together correctly...
            stash_to_append_to[@internal_name] = biomart_data
          else
            unless stash_to_append_to[@internal_name]
              stash_to_append_to[@internal_name] = []
            end
            
            biomart_data.each do |data|
              stash_to_append_to[@internal_name].push(data)
            end
          end
        end
      end
    end
    
  end
  
  # Utility function to clean up superscript text in biomart attributes
  # will convert text between <> tags to <sup></sup>, but leave other 
  # HTML formatted text alone.
  def fix_superscript_text_in_attribute( attribute )
    if attribute and attribute.match("<.+>.+</.+>")
      # HTML code - leave alone...
    elsif attribute and attribute.match("<.+>")
      match = /(.+)<(.+)>(.*)/.match(attribute);
      attribute = match[1] + "<sup>" + match[2] + "</sup>" + match[3];
    end
    
    return attribute;
  end
  
  def data_origin_url( query )
    attrs = []
    @attributes.each do |attribute|
      attrs.push("#{@dataset_name}.default.attributes.#{attribute}")
    end
    
    url = @url + "/martview?VIRTUALSCHEMANAME=default&VISIBLEPANEL=resultspanel&FILTERS="
    url << "#{@dataset_name}.default.filters.#{@joined_biomart_filter}.&quot;"
    
    if query.is_a?(Array) then url << "#{CGI::escape(query.join(","))}&quot;&ATTRIBUTES="
    else                       url << "#{CGI::escape(query)}&quot;&ATTRIBUTES="
    end
    
    while ( url.length + attrs.join("|").length ) > 2048
      # This loop ensures that the URL we form is not more than 2048 characters 
      # long - the maximum length that IE can deal with.  We do the shortening by 
      # dropping attributes from the selection, it's a pain, but at least it'll be 
      # easy for the user to add the attribute back in MartView.
      attrs.pop
    end
    url << attrs.join("|")
    
    return url
  end
  
  private
  
  # Utility function to read in a file and return it's contents 
  # as a string if the given test is true.
  def load_file_if_true( test, file_name )
    if test
      file      = File.new( "#{File.expand_path(File.dirname(__FILE__))}/../config/datasets/#{@internal_name}/#{file_name}","r")
      file_data = file.read
      file.close
      return file_data
    else
      nil
    end
  end
  
end