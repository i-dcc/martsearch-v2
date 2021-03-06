require File.dirname(__FILE__) + '/test_helper.rb'

class IndexTest < Test::Unit::TestCase
  
  context "The configured index" do
    
    should "have basic attributes" do
      assert( @@ms.index.url, ".url is nil - incorrect parsing of config?" )
      assert( @@ms.index.primary_field, ".primary_field is nil - incorrect parsing of config?" )
    end
    
    should "respond to pings" do
      assert( @@ms.index.is_alive?, "The search index is offline or misconfigured." )
    end
    
    should "fail gracefully when we mess with the url" do
      orig_url   = @@ms.index.url
      @@ms.index.url = "http://www.foo.com"
      assert_raise(IndexUnavailableError) { @@ms.index.is_alive? }
      @@ms.index.url = orig_url
    end
    
    should "correctly handle a simple (single item) search" do
      results = @@ms.index.search( @@ms.config["test"]["single_return_search"] )
      
      assert_not_equal( results, false, "The .search function failed." )
      assert( results.is_a?(Hash), ".search does not return a hash object." )
      assert( @@ms.index.current_results.is_a?(Hash), ".current_results does not return a hash object." )
      assert( @@ms.index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
      assert( @@ms.index.current_results_total === 1, ".current_results_total is not returning a number." )
      assert( @@ms.index.current_page === 1, ".current_page is not equal to 1." )
      
      # reset the index object
      @@ms.index = Index.new( @@ms.config["index"], @@ms.http_client )
    end
    
    should "correctly handle a more complicated (large) search" do
      results = @@ms.index.search( @@ms.config["test"]["large_search"] )
      
      assert_not_equal( results, false, "The .search function failed." )
      assert( results.is_a?(Hash), ".search does not return a hash object." )
      assert( @@ms.index.current_results.is_a?(Hash), ".current_results does not return a hash object." )
      assert( @@ms.index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
      assert( @@ms.index.current_results_total >= 0, ".current_results_total is not returning a number." )
      assert( @@ms.index.current_page === 1, ".current_page should equal 1." )
      
      results2 = @@ms.index.search( @@ms.config["test"]["large_search"], 4 )
      
      assert_not_equal( results2, false, "The .search function failed. (page 4)" )
      assert( results2.is_a?(Hash), ".search does not return a hash object. (page 4)" )
      assert( @@ms.index.current_results.is_a?(Hash), ".current_results does not return a hash object. (page 4)" )
      assert( @@ms.index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object. (page 4)" )
      assert( @@ms.index.current_results_total >= 0, ".current_results_total is not returning a number. (page 4)" )
      assert( @@ms.index.current_page === 4, ".current_page should equal 4." )
      
      # reset the index object
      @@ms.index = Index.new( @@ms.config["index"], @@ms.http_client )
    end
    
    should "correctly handle a bad (i.e. will cause an error) search" do
      assert_raise(IndexSearchError) { results = @@ms.index.search( @@ms.config["test"]["bad_search"] ) }
    end
    
    should "correctly handle count() requests" do
      single_result = @@ms.index.count( @@ms.config["test"]["single_return_search"] )
      assert( single_result.is_a?(Integer), ".count() does not return an Integer.")
      assert( single_result == 1, ".count() for #{@@ms.config["test"]["single_return_search"]} does not return 1.")
      
      multi_results = @@ms.index.count( @@ms.config["test"]["large_search"] )
      assert( multi_results.is_a?(Integer), ".count() does not return an Integer.")
      assert( multi_results > 1, ".count() for #{@@ms.config["test"]["large_search"]} does not return >1.")
      
      assert_raise(IndexSearchError) {
        bad_results = @@ms.index.count( @@ms.config["test"]["bad_search"] )
      }
    end
    
    should "correctly handle quick_search() requests" do
      single_result = @@ms.index.quick_search( @@ms.config["test"]["single_return_search"] )
      assert( single_result.is_a?(Array), ".quick_search() does not return an Array.")
      assert( single_result.size == 1, ".quick_search() for #{@@ms.config["test"]["single_return_search"]} does not return and array with 1 element.")
      
      multi_results = @@ms.index.quick_search( @@ms.config["test"]["large_search"] )
      assert( multi_results.is_a?(Array), ".quick_search() does not return an Array.")
      assert( multi_results.size > 1, ".quick_search() for #{@@ms.config["test"]["large_search"]} does not return an array with >1 element.")
      
      assert_raise(IndexSearchError) {
        bad_results = @@ms.index.quick_search( @@ms.config["test"]["bad_search"] )
      }
    end
    
  end
  
end