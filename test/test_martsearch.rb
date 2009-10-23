require File.dirname(__FILE__) + '/test_helper.rb'

class MartsearchTest < Test::Unit::TestCase
  context "A Martsearch object" do
    should "have basic attributes" do
      assert( !@@ms.config.nil?, "The Martsearch object does not have a configuration structure." )
      assert( !@@ms.index.nil?, "The Martsearch object does not have an Index object." )
      assert( @@ms.datasets.size > 0, "The Martsearch object does not have any Dataset objects." )
    end
    
    should "correctly handle a simple (single item) search" do
      results = @@ms.search( @@ms.config["test"]["single_return_search"], nil )
      
      assert( results.is_a?(Hash), "The Martsearch.search() return is not a hash." )
      assert( !results[results.keys.first]["index"].nil?, "The Martsearch.search() return doesn't have any index data." )
      @@ms.datasets.each do |ds|
        assert( !results[results.keys.first][ ds.dataset_name ].nil?, "The Martsearch.search() return doesn't have any data from #{ds.dataset_name}." )
      end
    end
    
    should "correctly handle a more complicated (large) search" do
      results = @@ms.search( @@ms.config["test"]["large_search"], nil )
      
      assert( results.is_a?(Hash), "The Martsearch.search() return is not a hash." )
      assert( !results[results.keys.first]["index"].nil?, "The Martsearch.search() return doesn't have any index data." )
      @@ms.datasets.each do |ds|
        assert( !results[results.keys.first][ ds.dataset_name ].nil?, "The Martsearch.search() return doesn't have any data from #{ds.dataset_name}." )
      end
    end
    
    should "correctly handle a bad (destined to fail) search" do
      results = @@ms.search( @@ms.config["test"]["bad_search"], nil )
      
      assert( results.nil?, "A search that returns 0 results is not flagged as nil." )
    end
  end
  
end