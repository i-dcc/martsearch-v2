require "#{File.dirname(__FILE__)}/test_helper.rb"
require "#{File.dirname(__FILE__)}/../martsearchr.rb"
require "rack/test"

set :environment, :test
set :logging, false
set :public, "#{File.dirname(__FILE__)}/../public"
set :views, "#{File.dirname(__FILE__)}/../views"

class MartsearchUiTest < Test::Unit::TestCase
  context "A MartSearch application" do
    setup do
      @browser = Rack::Test::Session.new( Rack::MockSession.new( Sinatra::Application ) )
    end

    should "have the portal name in the header" do
      @browser.get "/"
      assert( @browser.last_response.ok?, "Unable to make request to '/'." )
      assert( @browser.last_response.body.include?("<h1>#{@@ms.config["portal_name"]}</h1>"), "The templates do not include the portal name." )
    end
  end
  
end