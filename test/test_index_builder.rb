require "#{File.dirname(__FILE__)}/test_helper.rb"

class IndexBuilderTest < Test::Unit::TestCase
  context "An index builder object" do
    setup do
      @index_builder = IndexBuilder.new("#{File.dirname(__FILE__)}/../config/config.json")
      @index_builder.test_environment = true
      
      ##
      ## Build accessors for private methods
      ##
      
      def @index_builder.process_attribute_map_public(*args)
        process_attribute_map(*args)
      end
      
      def @index_builder.biomart_dataset_pulic(*args)
        biomart_dataset(*args)
      end
      
      def @index_builder.cache_documents_by_public(*args)
        cache_documents_by(*args)
      end
      
      def @index_builder.process_dataset_results_public(*args)
        process_dataset_results(*args)
      end
      
      def @index_builder.clean_document_public(*args)
        clean_document(*args)
      end
    end

    should "have basic attributes" do
      assert( @index_builder.martsearch.is_a?(Martsearch), "@index_builder.martsearch is not a Martsearch object." )
      assert( @index_builder.index_conf.is_a?(Hash), "@index_builder.index_conf is not a config hash." )
    end
    
    ##
    ## Testing the Solr XML schema creation
    ##
    
    should "generate a Solr XML schema" do
      solr_schema = @index_builder.solr_schema()
      assert( !solr_schema.nil?, "The @index_builder.solr_schema method returned nil." )
      assert( solr_schema.is_a?(String), "@index_builder.solr_schema did not return a string value." )
      # TODO: If/when there is a DTD to validate the Solr XML against - use it!
    end
    
    ##
    ## Testing the Solr index XML building
    ##
    
    should "act as expected when we simulate the document building process..." do
      @index_builder.index_conf["datasets"].each do |dataset_conf|
        # attribute_map processing
        mapping_data = @index_builder.process_attribute_map_public( dataset_conf["indexing"]["attribute_map"] )
        assert( mapping_data.is_a?(Hash), "@index_builder.process_attribute_map does not return a Hash." )
        assert( !mapping_data[:attribute_map].nil?, "@index_builder.process_attribute_map does not return an attribute_map." )
        assert( !mapping_data[:primary_attribute].nil?, "@index_builder.process_attribute_map does not return a primary_attribute." )
        assert( !mapping_data[:map_to_index_field].nil?, "@index_builder.process_attribute_map does not return a map_to_index_field." )
        assert( mapping_data[:attribute_map].is_a?(Hash), "@index_builder.process_attribute_map does not return attribute_map as a Hash." )
        assert( mapping_data[:primary_attribute].is_a?(String), "@index_builder.process_attribute_map does not return primary_attribute as a String." )
        assert( mapping_data[:map_to_index_field].is_a?(String), "@index_builder.process_attribute_map does not return map_to_index_field as a String." )
        
        attribute_map      = mapping_data[:attribute_map]
        primary_attribute  = mapping_data[:primary_attribute]
        map_to_index_field = mapping_data[:map_to_index_field]
        
        # document caching
        unless map_to_index_field == @index_builder.index_conf["schema"]["unique_key"]
          cache_documents_by_public( map_to_index_field )
          assert( !@index_builder.documents_by[map_to_index_field].nil?, "The document cache (made by cache_documents_by()) is nil." )
          assert( @index_builder.documents_by[map_to_index_field].is_a?(Hash), "The document cache (made by cache_documents_by()) is not a Hash." )
        end
        
        # Biomart::Dataset object creation
        mart = @index_builder.biomart_dataset_pulic( dataset_conf )
        assert( mart.is_a?(Biomart::Dataset), "@index_builder.biomart_dataset does not return a Biomart::Dataset object." )
        
        # Biomart result processing
        begin
          results = mart.search( :attributes => attribute_map.keys, :filters => { "marker_symbol" => ["Akt2","Cbx7"] } )
          @index_builder.process_dataset_results_public( dataset_conf, results, attribute_map, map_to_index_field, primary_attribute )
        rescue Biomart::FilterError => error
          # This dataset does not have a "marker_symbol" filter so we can't test 
          # it with this simple test... not too much of a worry...
        end
        
        assert( !@index_builder.documents.empty?, "@index_builder.documents is empty! - Should have at least two entries..." )
      end
      
      # Document cleaning...
      @index_builder.documents.values.each do |doc|
        @index_builder.clean_document_public(doc)
      end
      
      #p @index_builder.documents
    end
    
    ## NOTE: Uncomment the following to run a FULL test of the document 
    ##       collation - this will run a complete document build from all the 
    ##       datasets (possibly taking a hell of a long time)
    
    #should "build a hash of 'documents' containing information to be indexed" do
    #  assert( @index_builder.documents.is_a?(Hash), "The @index_builder.documents construct is not a Hash." )
    #  assert( @index_builder.documents.empty?, "The default @index_builder.documents hash is NOT empty." )
    #  
    #  @index_builder.build_documents()
    #  
    #  assert( @index_builder.documents.is_a?(Hash), "The @index_builder.documents construct is not a Hash." )
    #  assert( !@index_builder.documents.empty?, "@index_builder.build_documents has NOT populated @index_builder.documents." )
    #end
  end
end