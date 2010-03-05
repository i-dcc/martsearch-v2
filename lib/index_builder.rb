# This class is responsible for the set-up, building and updating 
# of a Solr search index for use with a MartSearchr application.
class IndexBuilder
  attr_reader :martsearch, :config, :documents, :documents_by, :xml_dir
  attr_accessor :test_environment
  
  def initialize( config_desc )
    @test_environment = false
    
    @config = nil
    if config_desc.is_a?(String)
      @config = JSON.load( File.new( config_desc, "r" ) )["index"]
    else
      @config = config_desc["index"]
    end
    @config["datasets"] = dataset_index_conf()
    
    @solr       = RSolr.connect :url => @config["url"]
    @batch_size = 1000
    
    # Create a placeholder variable to store docs in (and a cache variable 
    # for faster lookups if required...)
    @documents    = {}
    @documents_by = {}
    
    @current = { :dataset_conf => nil, :biomart => nil }
    @xml_dir = nil
  end
  
  # Function to create the Solr XML Schema used to define 
  # how our search engine is structured
  def solr_schema_xml
    template = File.open( "#{File.dirname(__FILE__)}/schema.xml.erb", 'r' )
    erb      = ERB.new( template.read, nil, "-" )
    schema   = erb.result( binding )
    return schema
  end
  
  # Function to build the documents array for pushing into our index.  
  # Does this by pulling all of the available data from each dataset 
  # and processing each returned result according to the "indexing" 
  # config defined on a per-dataset basis.
  def build_documents
    @config["datasets"].each do |dataset_conf|
      unless @test_environment then puts "Building documents for dataset: '#{dataset_conf["display_name"]}'" end
      
      # Store the 'current' target dataset and biomart conf
      @current[:dataset_conf] = dataset_conf
      @current[:biomart]      = biomart_dataset( dataset_conf )
      
      # Extract all of the needed index mapping data from "attribute_map"
      map_data = process_attribute_map( dataset_conf )
      
      # Do we need to cache lookup data?
      unless map_data[:map_to_index_field].to_sym == @config["schema"]["unique_key"].to_sym
        cache_documents_by( map_data[:map_to_index_field] )
      end
      
      # Grab a Biomart::Dataset object and search and retrieve all the data it holds
      unless @test_environment then puts "  - retrieving data from the biomart." end
      
      biomart_search_params = {
        :attributes => map_data[:attribute_map].keys,
        :timeout => 240
      }
      
      if dataset_conf["indexing"]["filters"]
        biomart_search_params[:filters] = dataset_conf["indexing"]["filters"]
      end
      
      results = @current[:biomart].search(biomart_search_params)
      
      # Now loop through the results building up document structures
      unless @test_environment
        puts "  - processing #{results[:data].size} rows of Biomart results"
      end
      process_dataset_results( results )
    end
    
    # Finally, remove duplicates from our documents
    @documents.values.each do |doc|
      clean_document(doc)
    end
  end
  
  # Function to build and store the XML files needed to update a Solr 
  # index based on the @documents store in this current instance.  If 
  # a directory location is passed as an argument it'll save the XML 
  # files there, otherwise it'll save to a temporary directory.
  def build_document_xmls( path=false )
    unless @test_environment
      puts "Creating Solr XML files (#{@batch_size} docs per file)..."
    end
    
    dir = nil
    if path
      dir = path
    else
      dir = Dir.mktmpdir
    end
    
    doc_chunks = @documents.keys.chunk( @batch_size )
    doc_chunks.each_index do |chunk_number|
      unless @test_environment
        puts "[ #{chunk_number + 1} / #{doc_chunks.size} ]"
      end
      
      doc_names = doc_chunks[chunk_number]
      docs = []
      doc_names.each do |name|
        docs.push( @documents[name] )
      end
      
      file = File.open( "#{dir}/solr-xml-#{chunk_number+1}.xml", "w" )
      file.print solr_document_xml(docs)
      file.close
    end
    
    @xml_dir = dir
  end
  
  # Function to post our @documents to the Solr instance.
  def send_documents_to_solr
    unless @test_environment
      puts "Uploading Solr documents in batches of #{@batch_size}..."
    end
    
    doc_chunks = @documents.keys.chunk( @batch_size )
    doc_chunks.each_index do |chunk_number|
      unless @test_environment
        puts "[ #{chunk_number + 1} / #{doc_chunks.size} ]"
      end
      
      doc_names = doc_chunks[chunk_number]
      docs = []
      doc_names.each do |name|
        docs.push( @documents[name] )
      end
      
      @solr.add docs
    end
    
    unless @test_environment
      puts "Commiting and optimizing documents..."
    end
    @solr.commit
    @solr.optimize
    unless @test_environment
      puts "Document upload completed."
    end
  end
  
  private
  
  ##
  ## General Utility functions
  ##
  
  # Utility function to grab the index configuration from each of 
  # the datasets to be added into our @config.
  def dataset_index_conf
    dataset_conf = []
    @config["datasets_to_index"].each do |ds_name|
      ds_conf = JSON.load( File.new("#{File.dirname(__FILE__)}/../config/datasets/#{ds_name}/config.json","r") )
      if ds_conf["index"] and !ds_conf["indexing"].nil?
        ds_conf["internal_name"] = ds_name
        dataset_conf.push( ds_conf )
      end
    end
    return dataset_conf
  end
  
  # Utility function to either find or create a Biomart::Dataset object
  def biomart_dataset( ds_conf )
    return Biomart::Dataset.new( ds_conf["url"], { :name => ds_conf["dataset_name"] } )
  end
  
  ##
  ## Utility functions specific for building the XML to prime a 
  ## Solr index
  ##
  
  # Utility function to process the attribute_map configuration into 
  # something we can use to map biomart results to our index configuration.
  def process_attribute_map( dataset_conf )
    attribute_map      = dataset_conf["indexing"]["attribute_map"]
    
    map                = {}
    primary_attribute  = nil
    map_to_index_field = nil
    
    # Extract all of the needed index mapping data from the "attribute_map"
    # - The "attribute_map" defines how the biomart attributes relate to the index "fields"
    # - The "primary_attribute" is the biomart attribute used to associate a set of biomart 
    #   results to an index "doc" - using the "map_to_index_field" field as the link.
    attribute_map.each do |mapping_obj|
      if mapping_obj["use_to_map"]
        if primary_attribute
          raise StandardError "You have defined more than one attribute to map to the index with! Please check your config..."
        else
          primary_attribute  = mapping_obj["attr"]
          map_to_index_field = mapping_obj["idx"].to_sym
        end
      end
      
      map[ mapping_obj["attr"] ]        = mapping_obj
      map[ mapping_obj["attr"] ]["idx"] = map[ mapping_obj["attr"] ]["idx"].to_sym
    end
    
    unless primary_attribute
      raise StandardError "You have not specified an attribute to map to the index with in #{dataset_conf["internal_name"]}!"
    end
    
    return {
      :attribute_map      => map,
      :primary_attribute  => primary_attribute,
      :map_to_index_field => map_to_index_field
    }
  end
  
  # Utility function to create a new document construct.
  def new_document()
    # Work out fields to ignore - these will be auto populated by Solr
    copy_fields = []
    @config["schema"]["copy_fields"].each do |copy_field|
      copy_fields.push( copy_field["dest"] )
    end
    
    doc = {}
    @config["schema"]["fields"].each do |key,detail|
      unless copy_fields.include?(key)
        doc[ key.to_sym ] = []
      end
    end
    return doc
  end
  
  # Utility function to find a specific document (i.e. for a gene), arguments 
  # are the field to search on, and the term to find.
  def find_document( field, search_term )
    if field == @config["schema"]["unique_key"].to_sym
      return @documents[search_term]
    else
      if @documents_by[field][search_term]
        return @documents[ @documents_by[field][search_term] ]
      else
        return nil
      end
    end
  end
  
  # Utility function to cache the document store by a given field.  This 
  # allows a much faster lookup of documents when we are not linking by 
  # the primary field.
  def cache_documents_by( field )
    # Test to see if we really need to build the cache - it could have 
    # already been done by a previous dataset...
    build_cache = true
    if @documents_by[field] and ( @documents.keys.size === @documents_by[field].keys.size )
      build_cache = false
    end
    
    if build_cache
      unless @test_environment
        puts "  - caching documents by '#{field}'"
      end
      @documents_by[field] = {}
      @documents.each do |key,values|
        values[field].each do |value|
          @documents_by[field][value] = key
        end
      end
    end
  end
  
  # Utility function to convert an array of data to a hash
  def convert_array_to_hash( headers, data )
    converted_data = {}
    headers.each_index do |position|
      if data[position].nil? or data[position] === ""
        converted_data[ headers[position] ] = nil
      else
        converted_data[ headers[position] ] = data[position]
      end
      
    end
    return converted_data
  end
  
  # Utility function to run through all of the results returned from 
  # the dataset and either create document constructs or append data to 
  # existing document constructs.
  def process_dataset_results( results )
    # Extract all of the needed index mapping data from "attribute_map"
    map_data = process_attribute_map( @current[:dataset_conf] )
    
    # Now loop through the result data...
    results[:data].each do |data_row|
      # First, create a hash out of the data_row and get the primary_attr_value
      data_row_obj       = convert_array_to_hash( results[:headers], data_row )
      primary_attr_value = data_row_obj[ map_data[:primary_attribute] ]
      
      # First check we have something to map back to the index with - if not, move along...
      if primary_attr_value
        # Find us a doc object to map to...
        value_to_look_up_doc_on = extract_value_to_index( map_data[:primary_attribute], primary_attr_value, map_data[:attribute_map], data_row_obj )
        doc                     = find_document( map_data[:map_to_index_field], value_to_look_up_doc_on )
        
        # If we can't find one - see if we're allowed to create one
        unless doc
          if @current[:dataset_conf]["indexing"]["allow_document_creation"]
            @documents[ value_to_look_up_doc_on ] = new_document()
            doc = @documents[ value_to_look_up_doc_on ]
          end
        end
        
        # Okay, if we have a doc - process the biomart attributes
        if doc
          # Now do the processing
          data_row_obj.each do |attr_name,attr_value|
            # Extract and index our initial data return
            value_to_index = extract_value_to_index( attr_name, attr_value, map_data[:attribute_map], data_row_obj )
            
            if value_to_index and doc[ map_data[:attribute_map][attr_name]["idx"] ]
              if value_to_index.is_a?(Array)
                value_to_index.each do |value|
                  doc[ map_data[:attribute_map][attr_name]["idx"] ].push( value )
                end
              else
                doc[ map_data[:attribute_map][attr_name]["idx"] ].push( value_to_index )
              end
            end
            
            # Any further metadata to be extracted from here? (i.e. MP terms in comments)
            if value_to_index and map_data[:attribute_map][attr_name]["extract"]
              regexp  = Regexp.new( map_data[:attribute_map][attr_name]["extract"]["regexp"] )
              matches = false
              
              if value_to_index.is_a?(Array)
                value_to_index.each do |value|
                  unless matches
                    matches = regexp.match( value )
                  end
                end
              else
                matches = regexp.match( value_to_index )
              end
              
              if matches
                doc[ map_data[:attribute_map][attr_name]["extract"]["idx"].to_sym ].push( matches[0] )
              end
            end
          end
          
          # Finally - do we have any attributes that we need to group together?
          if @current[:dataset_conf]["indexing"]["grouped_attributes"]
            @current[:dataset_conf]["indexing"]["grouped_attributes"].each do |group|
              attrs = []
              group["attrs"].each do |attribute|
                value_to_index = extract_value_to_index( attribute, data_row_obj[attribute], map_data[:attribute_map], { attribute => data_row_obj[attribute] } )
                attrs.push(value_to_index)
              end
              
              # Only index when we have values for ALL the grouped attributes
              if attrs.size() === group["attrs"].size()
                join_str = group["using"] ? group["using"] : "||"
                doc[ group["idx"].to_sym ].push( attrs.join(join_str) )
              end
            end
          end
        end
      end
    end
  end
  
  # Utility function to determine what data values we need to 
  # add to the index given the dataset configuration.
  def extract_value_to_index( attr_name, attr_value, attr_options, mart_data )
    options         = attr_options[attr_name]
    value_to_index  = attr_value

    if options["if_attr_equals"]
      unless options["if_attr_equals"].include?( attr_value )
        value_to_index = nil
      end
    end

    if options["index_attr_name"]
      if value_to_index
        mart_attributes = @current[:biomart].attributes()
        value_to_index  = [ attr_name, mart_attributes[attr_name].display_name ]
      end
    end

    if options["if_other_attr_indexed"]
      other_attr       = options["if_other_attr_indexed"]
      other_attr_value = mart_data[ other_attr ]

      unless extract_value_to_index( other_attr, other_attr_value, attr_options, mart_data )
        value_to_index = nil
      end
    end
    
    unless value_to_index.nil?
      if options["attr_prepend"]
        value_to_index = "#{options["attr_prepend"]}#{value_to_index}"
      end
      if options["attr_append"]
        value_to_index = "#{value_to_index}#{options["attr_append"]}"
      end
    end

    return value_to_index
  end
  
  # Utility function to remove any duplication from a document construct.
  def clean_document( doc )
    doc.each do |key,value|
      if value.size > 0
        doc[key] = value.uniq
      end
      
      # If we have multiple value entries in what should be a single valued 
      # field, not the best solution, but just arbitrarily pick the first entry.
      if !@config["schema"]["fields"][key.to_s]["multi_valued"] and value.size > 1
        new_array = []
        new_array.push(value[0])
        doc[key]  = new_array
      end
    end
  end
  
  ##
  ## Utility functions for creating and handling XML files
  ##
  
  # Utility function to create the actual XML markup for a collection 
  # of document constructs.
  def solr_document_xml( docs )
    solr_xml = ""
    xml      = Builder::XmlMarkup.new( :target => solr_xml, :indent => 2 )
    
    xml.add {
      docs.each do |doc|
        xml.doc {
          doc.each do |field,field_terms|
            field_terms.each do |term|
              xml.field( term, :name => field )
            end
          end
        }
      end
    }
    
    return solr_xml
  end
end