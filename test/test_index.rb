require File.dirname(__FILE__) + '/test_helper.rb'

class IndexTest < Test::Unit::TestCase
  def setup
    @http_client = Net::HTTP
    if ENV['http_proxy']
      proxy = URI.parse( ENV['http_proxy'] )
      @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
    end

    config_file = File.new( File.dirname(__FILE__) + "/../config/config.json", "r" )
    @config     = JSON.load(config_file)

    @index = Index.new( @config["index"], @http_client )
  end
  
  context "The configured index" do
    should "respond to pings" do
      assert( @index.is_alive?, "The search index is offline or misconfigured." )
    end
    
    should "fail when we mess with the url" do
      orig_url   = @index.url
      @index.url = "http://www.foo.com"
      assert( !@index.is_alive?, "The .is_alive? function does not correctly report a broken index." )
      @index.url = orig_url
    end
  end
  
end