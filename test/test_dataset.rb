require File.dirname(__FILE__) + '/test_helper.rb'

class DatasetTest < Test::Unit::TestCase
  
  context "A Dataset object" do
    setup do
      @ds = @@ms.datasets.first
    end
    
    should "correctly format superscript text" do
      expected_text = "Akt2<sup>tm1Wcs</sup>"
      test_text1 = "Akt2<tm1Wcs>"
      test_text2 = "Akt2<sup>tm1Wcs</sup>"
      
      assert_equal( expected_text, @ds.fix_superscript_text_in_attribute(test_text1), "#{test_text1} superscript was not correctly tranformed.")
      assert_equal( expected_text, @ds.fix_superscript_text_in_attribute(test_text2), "#{test_text2} superscript was not correctly tranformed.")
    end
  end
  
  @@ms.datasets.each do |dataset|
    context "Dataset '#{dataset.dataset_name}'" do
      
      should "have basic attributes" do
        assert( dataset.url, ".url is nil - incorrect parsing of config?" )
        assert( dataset.dataset_name, ".display_name is nil - incorrect parsing of config?" )
      end
      
      should "respond to pings" do
        assert( dataset.is_alive?, "The biomart dataset #{dataset.dataset_name} is offline or misconfigured." )
      end
      
      should "fail gracefully when we mess with the url" do
        orig_url    = dataset.url
        dataset.url = "http://www.foo.com"
        dataset.reload_dataset
        
        assert_equal( false, dataset.is_alive?, "The .is_alive? function does not correctly report a broken dataset." )
        
        dataset.url = orig_url
        dataset.reload_dataset
      end
      
      should "correctly handle a simple (single item) search" do
        test_search( dataset, "single_return_search" )
      end
      
      should "correctly handle a more complicated (large) search" do
        test_search( dataset, "large_search" )
      end
      
      should "generate a biomart search link url" do
        
      end
      
    end
  end
  
  def test_search( dataset, search_param )
    # Query the index
    results = @@ms.index.search( @@ms.config["test"][search_param] )
    
    assert_not_equal( results, false, "The .search function failed." )
    assert( results.is_a?(Hash), ".search does not return a hash object." )
    assert( @@ms.index.grouped_terms.is_a?(Hash), ".grouped_terms does not return a hash object." )
    
    # Now fetch the pre-computed biomart search terms 
    # and search the dataset
    search_terms = @@ms.index.grouped_terms[ dataset.joined_index_field ]
    assert( search_terms.is_a?(Array), "The retrieved search terms are not in an array." )
    
    mart_results = dataset.search( search_terms )
    assert( mart_results.is_a?(Hash), "The Biomart results are not in a hash." )
    
    dataset.add_to_results_stash( results, mart_results )
    assert( results.is_a?(Hash), "The results stash is no longer a hash." )
  end
  
end