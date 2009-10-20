require File.dirname(__FILE__) + '/test_helper.rb'

class DatasetTest < Test::Unit::TestCase
  
  @@datasets.each do |dataset|
    context "Dataset '#{dataset.display_name}'" do
      
      should "have basic attributes" do
        assert( dataset.url, ".url is nil - incorrect parsing of config?" )
        assert( dataset.display_name, ".display_name is nil - incorrect parsing of config?" )
      end
      
      should "respond to pings" do
        assert( dataset.is_alive?, "The biomart dataset #{dataset.dataset_name} is offline or misconfigured." )
      end
      
      should "fail gracefully when we mess with the url" do
        orig_url   = dataset.url
        dataset.url = "http://www.foo.com"
        assert_equal( dataset.is_alive?, false, "The .is_alive? function does not correctly report a broken dataset." )
        dataset.url = orig_url
      end
      
      should "correctly handle a simple (single item) search" do
        
      end
      
      should "correctly handle a more complicated (large) search" do
        
      end
      
      should "generate a biomart search link url" do
        
      end
      
    end
  end
  
end