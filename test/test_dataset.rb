require File.dirname(__FILE__) + '/test_helper.rb'

class DatasetTest < Test::Unit::TestCase
  
  @http_client = Net::HTTP
  if ENV['http_proxy']
    proxy = URI.parse( ENV['http_proxy'] )
    @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
  end
  
  config_file = File.new( File.dirname(__FILE__) + "/../config/config.json", "r" )
  @config     = JSON.load(config_file)
  
  @index = Index.new( @config["index"], @http_client )
  
  @datasets = []
  @config["datasets"].each do |ds|
    ds_conf_file = File.new( File.dirname(__FILE__) + "/../config/datasets/#{ds}/config.json","r")
    ds_conf      = JSON.load(ds_conf_file)
    @datasets.push( Dataset.new( ds_conf, @http_client ) )
  end
  
  @datasets.each do |dataset|
    context "Dataset '#{dataset.display_name}'" do
      
      should "respond to pings" do
        assert( dataset.is_alive?, "The biomart dataset #{dataset.dataset_name} is offline or misconfigured." )
      end
      
      should "fail gracefully when we mess with the url" do
        
      end
      
      should "correctly handle a simple (single item) search" do
        
      end
      
      should "correctly handle a more complicated (large) search" do
        
      end
      
    end
  end
  
end