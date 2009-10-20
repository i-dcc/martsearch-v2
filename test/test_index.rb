require File.dirname(__FILE__) + '/test_helper.rb'

class IndexTest < Test::Unit::TestCase
  
  context "The configured index" do
    
    should "have basic attributes" do
      assert( @@index.url, ".url is nil - incorrect parsing of config?" )
      assert( @@index.primary_field, ".primary_field is nil - incorrect parsing of config?" )
    end
    
    should "respond to pings" do
      assert( @@index.is_alive?, "The search index is offline or misconfigured." )
    end
    
    should "fail gracefully when we mess with the url" do
      orig_url   = @@index.url
      @@index.url = "http://www.foo.com"
      assert_equal( @@index.is_alive?, false, "The .is_alive? function does not correctly report a broken index." )
      @@index.url = orig_url
    end
    
    should "correctly handle a simple (single item) search" do
      results = @@index.search( @@config["test"]["single_return_search"] )
      
      assert_not_equal( results, false, "The .search function failed." )
      assert( results.is_a?(Hash), ".search does not return a hash object." )
      assert( @@index.current_results.is_a?(Hash), ".current_results does not return a hash object." )
      assert( @@index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
      assert( @@index.current_results_total === 1, ".current_results_total is not returning a number." )
      assert( @@index.current_page === 1, ".current_page is not equal to 1." )
      
      # reset the index object
      @@index = Index.new( @@config["index"], @@http_client )
    end
    
    should "correctly handle a more complicated (large) search" do
      results = @@index.search( @@config["test"]["large_search"] )
      
      assert_not_equal( results, false, "The .search function failed." )
      assert( results.is_a?(Hash), ".search does not return a hash object." )
      assert( @@index.current_results.is_a?(Hash), ".current_results does not return a hash object." )
      assert( @@index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
      assert( @@index.current_results_total >= 0, ".current_results_total is not returning a number." )
      assert( @@index.current_page === 1, ".current_page should equal 1." )
      
      results2 = @@index.search( @@config["test"]["large_search"], 4 )
      
      assert_not_equal( results2, false, "The .search function failed. (page 4)" )
      assert( results2.is_a?(Hash), ".search does not return a hash object. (page 4)" )
      assert( @@index.current_results.is_a?(Hash), ".current_results does not return a hash object. (page 4)" )
      assert( @@index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object. (page 4)" )
      assert( @@index.current_results_total >= 0, ".current_results_total is not returning a number. (page 4)" )
      assert( @@index.current_page === 4, ".current_page should equal 4." )
      
      # reset the index object
      @@index = Index.new( @@config["index"], @@http_client )
    end
    
    should "correctly handle a bad (i.e. will cause an error) search" do
      results = @@index.search( @@config["test"]["bad_search"] )
      
      assert_equal( results, false, "The .search function does not return false in event of an error." )
    end
    
  end
  
end