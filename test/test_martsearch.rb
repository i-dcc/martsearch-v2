require File.dirname(__FILE__) + '/test_helper.rb'

class MartsearchTest < Test::Unit::TestCase
  context "Creating a MartSearch object" do
    should "be possible with a filename" do
      json_file = File.dirname(__FILE__) + "/../config/config.json"
      json_obj  = JSON.load( File.new( json_file, "r" ) )
      ms = Martsearch.new( json_file )
      assert( ms.is_a?(Martsearch), "A MartSearch object cannot be created from a file location." )
      assert_equal( json_obj, ms.config, "The MartSearch object has not correctly parsed the JSON file." )
    end
    
    should "be possible from a Ruby hash/object" do
      conf = @@ms.config.clone
      ms = Martsearch.new( conf )
      assert( ms.is_a?(Martsearch), "A martsearch object cannot be created from a configuration hash/object." )
      assert_equal( conf, ms.config, "The MartSearch object has not correctly accepeted the configuration hash/object." )
    end
  end
  
  context "A Martsearch object" do
    should "have basic attributes" do
      assert( !@@ms.config.nil?, "The Martsearch object does not have a configuration structure." )
      assert( !@@ms.index.nil?, "The Martsearch object does not have an Index object." )
      assert( @@ms.datasets.size > 0, "The Martsearch object does not have any Dataset objects." )
    end
    
    should "correctly handle a simple (single item) search" do
      results = @@ms.search( @@ms.config["test"]["single_return_search"], nil )
      data    = @@ms.search_data
      
      assert( results.is_a?(Array), "A MartSearch search does not return an array." )
      assert( results.size > 0, "The results array (from a MartSearch search) is empty." )
      
      assert( data.is_a?(Hash), "The Martsearch.search() return is not a hash." )
      assert( !data[data.keys.first]["index"].nil?, "The Martsearch.search() return doesn't have any index data." )
    end
    
    should "correctly handle a more complicated (large) search" do
      results = @@ms.search( @@ms.config["test"]["large_search"], nil )
      data    = @@ms.search_data
      
      assert( results.is_a?(Array), "A MartSearch search does not return an array." )
      assert( results.size > 0, "The results array (from a MartSearch search) is empty." )
      
      assert( data.is_a?(Hash), "The Martsearch.search() return is not a hash." )
      assert( !data[data.keys.first]["index"].nil?, "The Martsearch.search() return doesn't have any index data." )
    end
    
    should "correctly handle a bad (destined to fail) search" do
      results = @@ms.search( @@ms.config["test"]["bad_search"], nil )
      
      assert( results.is_a?(Array), "A MartSearch search does not return an array." )
      assert( results.empty?, "The results array (from a MartSearch search) is not empty." )
    end
    
    should "be able to send emails upon error" do
      assert_nothing_raised(Exception) {
        @@ms.send_email({
          :to      => "do2@sanger.ac.uk",
          :from    => "martsearch_testsuite@sanger.ac.uk",
          :subject => "MartSearch Test Suite Email",
          :body    => "Did it work?"
        })
      }
    end
  end
  
  context "The MartSearch cache" do
    setup do
      @config = @@ms.config.clone
    end
    
    should "allow the creation/use of a memory based cache" do
      @config["cache"] = true
      ms = Martsearch.new( @config )
      assert( ms.cache.is_a?(ActiveSupport::Cache::MemoryStore), "The memory based cache has not been initialised correctly." )
      
      test_file_and_memory_based_cache_use( ms.cache, "memory" )
    end
    
    should "allow the creation/use of a file based cache" do
      @config["cache"] = { "type" => "file" }
      ms = Martsearch.new( @config )
      assert( ms.cache.is_a?(ActiveSupport::Cache::FileStore), "The file based cache has not been initialised correctly." )
      
      @config["cache"] = { "type" => "file", "file_store" => "#{File.dirname(__FILE__)}/../tmp/cache" }
      ms = Martsearch.new( @config )
      assert( ms.cache.is_a?(ActiveSupport::Cache::FileStore), "The file based cache (with a custom location) has not been initialised correctly." )
      
      test_file_and_memory_based_cache_use( ms.cache, "file" )
    end
    
    should "allow the creation of a memcached based cache" do
      @config["cache"] = { "type" => "memcached" }
      ms = Martsearch.new( @config )
      assert( ms.cache.is_a?(ActiveSupport::Cache::MemCacheStore), "The memcached based cache has not been initialised correctly." )
      
      @config["cache"] = { "type" => "memcached", "servers" => ['192.168.1.1:11000', '192.168.1.2:11001'] }
      ms = Martsearch.new( @config )
      assert( ms.cache.is_a?(ActiveSupport::Cache::MemCacheStore), "The memcached based cache (with load balanced servers) has not been initialised correctly." )
      
      @config["cache"] = { "type" => "memcached", "namespace" => "foobar" }
      ms = Martsearch.new( @config )
      assert( ms.cache.is_a?(ActiveSupport::Cache::MemCacheStore), "The memcached based cache (with a custom namespace) has not been initialised correctly." )
      
      # Note: we do not actually test the use of memcached here as there's no 
      # guarantee of actually having a memcached server there to respond to! 
      # As it's a core part of ActiveSupport and Rails, we'll assume it's well tested...
    end
  end
  
  def test_file_and_memory_based_cache_use( cache, type )
    todays_date = Date.today
    cache.write( "date", todays_date )
    assert_equal( todays_date, cache.fetch("date"), "The #{type} based cache fell over storing a 'date' stamp!" )
    assert_equal( true, cache.exist?("date"), "The #{type} based cache fell over recalling a 'date' stamp!" )
    assert_equal( nil, cache.fetch("foo"), "The #{type} based cache does not return 'nil' upon an empty value." )
    
    cache.write( "foo", "bar", :expires_in => 1.second )
    sleep(2)
    assert( cache.exist?("foo"), "The :expires_in attribute on the #{type} based cache works?!?!?" )
    cache.delete_matched( Regexp.new(".*") )
    assert_equal( false, cache.exist?("foo"), "The 'delete_matched' method hasn't emptied out the cache..." )
  end
end