require "#{File.dirname(__FILE__)}/test_helper.rb"

class IndexBuilderTest < Test::Unit::TestCase
  ["file","memory"].each do |cache_type|
    context "An index builder object (with #{cache_type} based cache)" do
      setup do
        @index_builder = IndexBuilder.new("#{File.dirname(__FILE__)}/../config/config.json")
        @index_builder.test_environment = true
        
        build_public_methods( @index_builder )
      end

      should "have basic attributes" do
        assert( @index_builder.config.is_a?(Hash), "@index_builder.config is not a config hash." )
      end

      should "generate a Solr XML schema" do
        generate_solr_schema( @index_builder )
      end

      should "act as expected when we simulate the document building process..." do
        dir = Dir.mktmpdir
        Dir.chdir(dir) do
          @index_builder.initialize_file_based_cache() if cache_type == "file"
          simulate_building_process( @index_builder )
        end
        #puts "@index_builder (#{cache_type} based) cache and XML files written to #{dir}"
      end
    end
  end
  
  # Build accessors for private methods
  def build_public_methods( index_builder )
    def index_builder.process_attribute_map_public(*args)
      process_attribute_map(*args)
    end

    def index_builder.biomart_dataset_pulic(*args)
      biomart_dataset(*args)
    end

    def index_builder.cache_documents_by_public(*args)
      cache_documents_by(*args)
    end

    def index_builder.process_dataset_results_public(*args)
      process_dataset_results(*args)
    end

    def index_builder.get_document_public(*args)
      get_document(*args)
    end

    def index_builder.clean_document_cache_public(*args)
      clean_document_cache(*args)
    end
    
    def index_builder.current_public__set(args)
      self.instance_variable_set("@current", args)
    end
    
    def index_builder.current_public__get
      self.instance_variable_get("@current")
    end
  end
  
  # Testing the Solr XML schema creation
  def generate_solr_schema( index_builder )
    solr_schema = index_builder.solr_schema_xml()
    assert( !solr_schema.nil?, "The index_builder.solr_schema method returned nil." )
    assert( solr_schema.is_a?(String), "index_builder.solr_schema did not return a string value." )
    # TODO: If/when there is a DTD to validate the Solr XML against - use it!
  end
  
  # Testing the Solr index XML building
  def simulate_building_process( index_builder )
    index_builder.config["datasets"].each do |dataset_conf|
      # Store config and biomart objects
      index_builder.current_public__set({ 
        :dataset_conf => dataset_conf,
        :biomart      => index_builder.biomart_dataset_pulic( dataset_conf )
      })
      
      # attribute_map processing
      mapping_data = index_builder.process_attribute_map_public( dataset_conf )
      assert( mapping_data.is_a?(Hash), "index_builder.process_attribute_map does not return a Hash." )
      assert( !mapping_data[:attribute_map].nil?, "index_builder.process_attribute_map does not return an attribute_map." )
      assert( !mapping_data[:primary_attribute].nil?, "index_builder.process_attribute_map does not return a primary_attribute." )
      assert( !mapping_data[:map_to_index_field].nil?, "index_builder.process_attribute_map does not return a map_to_index_field." )
      assert( mapping_data[:attribute_map].is_a?(Hash), "index_builder.process_attribute_map does not return attribute_map as a Hash." )
      assert( mapping_data[:primary_attribute].is_a?(String), "index_builder.process_attribute_map does not return primary_attribute as a String." )
      assert( mapping_data[:map_to_index_field].is_a?(Symbol), "index_builder.process_attribute_map does not return map_to_index_field as a Symbol." )
      
      attribute_map      = mapping_data[:attribute_map]
      primary_attribute  = mapping_data[:primary_attribute]
      map_to_index_field = mapping_data[:map_to_index_field]
      
      # document caching
      unless map_to_index_field == index_builder.config["schema"]["unique_key"].to_sym
        index_builder.cache_documents_by_public( map_to_index_field )
        assert( !index_builder.document_cache_lookup[map_to_index_field].nil?, "The document cache (made by cache_documents_by()) is nil." )
        assert( index_builder.document_cache_lookup[map_to_index_field].is_a?(Hash), "The document cache (made by cache_documents_by()) is not a Hash." )
      end
      
      # Biomart::Dataset object creation
      mart = index_builder.current_public__get[:biomart]
      assert( mart.is_a?(Biomart::Dataset), "index_builder.biomart_dataset does not return a Biomart::Dataset object." )
      
      # Biomart result processing
      #puts "#{dataset_conf["internal_name"]}:"
      ["gene_symbol","marker_symbol","tmp_gene_symbol","marker_symbol_107"].each do |filter_type|
        begin
          #puts "  - testing: #{filter_type}"
          results = mart.search( :attributes => attribute_map.keys, :filters => { filter_type => ["Akt2","Cbx7","Cbx1","Mysm1"] } )
          index_builder.process_dataset_results_public( results )
          
          assert( index_builder.document_cache_keys.keys.size > 0, "index_builder.document_cache is empty! - Should have at least two entries..." )
          [ { "MGI:104874" => "Akt2" }, { "MGI:1196439" => "Cbx7" } ].each do |ids|
            assert( index_builder.get_document_public( ids.keys[0] ) != nil, "index_builder.document_cache does not contain a data entry for #{ids.values[0]}." )
            assert( index_builder.get_document_public( ids.keys[0] ).is_a?(Hash), "index_builder.document_cache does not contain a Hash for #{ids.values[0]}." )
          end
        rescue Biomart::FilterError => error
          #puts "  - failed: #{error}"
          # This dataset does not have a "marker_symbol" or "tmp_gene_symbol" filter so we can't test 
          # it with this simple test... not too much of a worry...
        rescue Timeout::Error => error
          # We should not fail the test suite because one of the biomarts is having a 
          # bad day - just ignore this mart and move along...
        end
      end
    end
    
    # Document cleaning...
    index_builder.clean_document_cache_public()
    index_builder.document_cache_keys.each_key do |cache_key|
      doc = index_builder.get_document_public(cache_key)
      assert( doc[ index_builder.config["schema"]["unique_key"].to_sym ].size === 1, "index_builder.clean_document_cache has not removed duplicate entries." )
    end
    
    # Saving the document XMLs
    index_builder.build_document_xmls()
    xml_files = Dir.glob("solr-*.xml")
    assert( xml_files.size > 0, "index_builder.build_document_xmls() did not produce any XML files." )
    
    #puts "Index docs in: #{index_builder.xml_dir}"
    
    # Upload XML to Solr
    #index_builder.send_documents_to_solr()
  end
end