require "#{File.dirname(__FILE__)}/test_helper.rb"
require "sinatra"
require "rack/test"

set :environment, :test
set :logging, false
set :public, "#{File.dirname(__FILE__)}/../public"
set :views, "#{File.dirname(__FILE__)}/../views"

CONF_FILE = "#{File.dirname(__FILE__)}/../config/config.json"

class MartsearchUiTest < Test::Unit::TestCase
  context "A MartSearch application" do
    setup do
      # Read in the config file
      conf_obj  = JSON.load( File.new( CONF_FILE, "r" ) )
      
      # Copy the config file for safe keeping
      system("cp #{CONF_FILE} #{CONF_FILE}.orig")
      
      # Alter the conf_obj and save it in place of the original conf_file
      conf_obj["base_uri"] = ""
      File.open( CONF_FILE, "w" ) { |f| f.write( conf_obj.to_json ) }
      
      require "#{File.dirname(__FILE__)}/../martsearchr.rb"
      
      # Now instanciate our MartSearch app
      @browser = Rack::Test::Session.new( Rack::MockSession.new( Sinatra::Application ) )
    end
    
    teardown do
      # Put our original conf file back
      File.delete(CONF_FILE)
      system("mv #{CONF_FILE}.orig #{CONF_FILE}")
    end

    should "have the portal name in the header" do
      @browser.get "/"
      assert( @browser.last_response.ok?, "Unable to make request to '/'." )
      assert( @browser.last_response.body.include?("<h1>#{@@ms.config["portal_name"]}</h1>"), "The templates do not include the portal name." )
    end
    
    should "have /about and /help pages" do
      ["/about","/about/","/help","/help/"].each do |path|
        @browser.get path
        assert( @browser.last_response.ok?, "Unable to make request to '#{path}'." )
      end
    end
    
    should "supply concatenated css and javascript files" do
      ["/css/martsearch.css","/js/martsearch.js"].each do |path|
        @browser.get path
        assert( @browser.last_response.ok?, "Unable to make request to '#{path}'." )
      end
    end
    
    should "allow admins to set messages for the users" do
      # HTML message file
      File.open("#{File.dirname(__FILE__)}/../messages/htmltest.html","w") do |f|
       f.write("This is a <em>test message</em>.")
      end
      
      # Markdown message file
      File.open("#{File.dirname(__FILE__)}/../messages/mdtest.markdown","w") do |f|
       f.write("This is a **test message**.")
      end
      
      @browser.get "/"
      assert( @browser.last_response.ok?, "Unable to make request to '/'." )
      assert( @browser.last_response.body.include?('<div id="status_msgs"'), "The templates do not include the status messages." )
      
      File.delete("#{File.dirname(__FILE__)}/../messages/htmltest.html")
      File.delete("#{File.dirname(__FILE__)}/../messages/mdtest.markdown")
      
      @browser.get "/"
      assert( @browser.last_response.ok?, "Unable to make request to '/'." )
      assert( !@browser.last_response.body.include?('<div id="status_msgs"'), "The templates include the status messages div when there are no messages!" )
    end
    
    should "allow you to manually clear the search cache" do
      ["/clear_cache","/clear_cache/"].each do |path|
        @browser.get path
        @browser.follow_redirect!
        assert_equal( "http://example.org/", @browser.last_request.url, "Cache emptying did not redirect to home page." )
        assert( @browser.last_response.ok? )
      end
    end
    
    should "handle 404's" do
      @browser.get "/wibble"
      assert( @browser.last_response.status == 404 )
    end
    
    should "handle a /search with no parameters correctly" do
      ["/search","/search/"].each do |path|
        @browser.get path
        @browser.follow_redirect!
        assert_equal( "http://example.org/", @browser.last_request.url, "Empty search did not redirect to home page." )
        assert( @browser.last_response.ok? )
      end
    end
    
    should "handle a /search with parameters" do
      search_with_params( @browser, "single_return_search" )
      search_with_params( @browser, "large_search" )
    end
    
    should "handle a /search response to the correct url" do
      search_to_url( @browser, "single_return_search" )
      search_to_url( @browser, "large_search" )
    end
    
    should "render the /browse page" do
      ["/browse","/browse/"].each do |path|
        @browser.get path
        assert( @browser.last_response.ok?, "Unable to make request to '#{path}'." )
      end
    end
    
    should "enable browsing of the data" do
      @@ms.config["browsable_content"].each do |name,conf|
        [ conf["options"][0], conf["options"][1] ].each do |param|
          param_string = param
          url_slug     = param
          if param.is_a?(Array)
            param_string = param[0]
            url_slug     = param[0]
          elsif param.is_a?(Hash)
            param_string = param["text"]
            url_slug     = param["slug"]
          end
          
          @browser.get "/browse/#{name}/#{url_slug.downcase}"
          assert( @browser.last_response.body.include?("Browsing Data by #{conf["display_name"]}: '#{param_string}'"), "Browse template not rendering the results header." )
          assert( @browser.last_response.ok?, "Unable to make request to '/browse/#{name}/#{param_string.downcase}'." )
        end
      end
    end
  end
  
  def search_with_params( browser, search_conf )
    browser.get "/search", :query => @@ms.config["test"][search_conf], :page => 1
    browser.follow_redirect!
    assert_equal( "http://example.org/search/#{@@ms.config["test"][search_conf]}/1", browser.last_request.url, "Simple search did not redirect to the search results page." )
    assert( browser.last_response.body.include?("Search Results for '#{@@ms.config["test"][search_conf]}'"), "Search template not rendering the search results header." )
    assert( browser.last_response.ok? )
    
    browser.get "/search", :query => @@ms.config["test"][search_conf]
    browser.follow_redirect!
    assert_equal( "http://example.org/search/#{@@ms.config["test"][search_conf]}", browser.last_request.url, "Simple search did not redirect to the search results page." )
    assert( browser.last_response.body.include?("Search Results for '#{@@ms.config["test"][search_conf]}'"), "Search template not rendering the search results header." )
    assert( browser.last_response.ok? )
  end
  
  def search_to_url( browser, search_conf )
    browser.get "/search/#{@@ms.config["test"][search_conf]}"
    assert_equal( "http://example.org/search/#{@@ms.config["test"][search_conf]}", browser.last_request.url, "Simple search did not redirect to the search results page." )
    assert( browser.last_response.body.include?("Search Results for '#{@@ms.config["test"][search_conf]}'"), "Search template not rendering the search results header." )
    assert( browser.last_response.ok? )
  end
end