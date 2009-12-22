require "#{File.dirname(__FILE__)}/test_helper.rb"

class IndexBuilderTest < Test::Unit::TestCase
  context "An index builder object" do
    setup do
      @index_builder = IndexBuilder.new("#{File.dirname(__FILE__)}/../config/config.json")
    end

    should "have basic attributes" do
      assert( @index_builder.martsearch.is_a?(Martsearch), "@index_builder.martsearch is not a Martsearch object." )
      assert( @index_builder.index_conf.is_a?(Hash), "@index_builder.index_conf is not a config hash." )
    end
    
    should "generate a Solr XML schema" do
      solr_schema = @index_builder.solr_schema()
      assert( !solr_schema.nil?, "The @index_builder.solr_schema method returned nil." )
      assert( solr_schema.is_a?(String), "@index_builder.solr_schema did not return a string value." )
      # TODO: If/when there is a DTD to validate the Solr XML against - use it!
    end
    
    
  end
end