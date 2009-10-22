require File.dirname(__FILE__) + '/test_helper.rb'

class DatasourceTest < Test::Unit::TestCase
  
  @@datasources.each do |datasource|
    context "Dataset '#{datasource.dataset_name}'" do
      
      should "have basic attributes" do
        assert( datasource.url, ".url is nil - incorrect parsing of config?" )
        assert( datasource.dataset_name, ".display_name is nil - incorrect parsing of config?" )
      end
      
      should "respond to pings" do
        assert( datasource.is_alive?, "The biomart datasource #{datasource.dataset_name} is offline or misconfigured." )
      end
      
      should "fail gracefully when we mess with the url" do
        orig_url    = datasource.url
        datasource.url = "http://www.foo.com"
        datasource.reload_dataset
        
        assert_equal( false, datasource.is_alive?, "The .is_alive? function does not correctly report a broken datasource." )
        
        datasource.url = orig_url
        datasource.reload_dataset
      end
      
      should "correctly handle a simple (single item) search" do
        test_search( datasource, "single_return_search" )
      end
      
      should "correctly handle a more complicated (large) search" do
        test_search( datasource, "large_search" )
      end
      
      should "generate a biomart search link url" do
        
      end
      
    end
  end
  
  def test_search( datasource, search_param )
    # Query the index
    results = @@index.search( @@config["test"][search_param] )
    
    assert_not_equal( results, false, "The .search function failed." )
    assert( results.is_a?(Hash), ".search does not return a hash object." )
    assert( @@index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
    
    # Now fetch the pre-computed biomart search terms 
    # and search the datasource
    search_terms = @@index.grouped_terms[ datasource.joined_index_field ]
    assert( search_terms.is_a?(Array), "The retrieved search terms are not in an array." )
    
    mart_results = datasource.search( search_terms, @@index.current_results )
    assert( mart_results.is_a?(Hash), "The Biomart results are not in a hash." )
    assert( mart_results.keys.size > 0, "The Biomart search did not retrieve any linked data.")
    
    datasource.add_to_results_stash( results, mart_results )
    assert( results.is_a?(Hash), "The results stash is no longer a hash." )
    
    test_result = results[ results.keys[0] ]
    assert_not_equal( test_result[ datasource.dataset_name ], nil, "The results stash doesn't contain data from #{datasource.dataset_name}." )
  end
  
end