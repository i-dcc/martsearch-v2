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

class SangerPhenotypingUiTest < Test::Unit::TestCase
  context "The Sanger Mouse Portal Phenotyping Section" do
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

    should "be able to render the heatmap page" do
      @browser.get "/phenotyping/heatmap"
      assert( @browser.last_response.ok?, "Unable to make request to '/phenotyping/heatmap'." )
      
      # Query for second time to test from primed cache
      @browser.get "/phenotyping/heatmap"
      assert( @browser.last_response.ok?, "Unable to make request to '/phenotyping/heatmap'." )
    end
    
    should "be able to render randomly selected phenotyping details pages" do
      colonies_with_images = find_pheno_images()
      assert( colonies_with_images.is_a?(Hash), "Function find_pheno_images() is not returning a hash." )
      
      # Take a random sample of 3 colonies, and then request three
      # tests at random from these colonies and view the details pages...
      random_colonies = colonies_with_images.keys.sort_by { rand }[0..2]
      random_colonies.each do |colony_prefix|
        random_tests = colonies_with_images[colony_prefix].keys.sort_by { rand }[0..2]
        random_tests.each do |test|
          view_pheno_details_page( @browser, colony_prefix, test )
        end
      end
    end
    
    should "be able to render ABR phenotyping details pages" do
      colonies_with_data = find_pheno_abr_results()
      assert( colonies_with_data.is_a?(Array), "Function find_pheno_abr_results() is not returning an array." )
      
      # Take a random sample of 3 colonies, and then request the pages
      random_colonies = colonies_with_data.sort_by { rand }[0..2]
      random_colonies.each do |colony_prefix|
        check_abr_redirect( @browser, colony_prefix )
        view_pheno_details_page( @browser, colony_prefix, "abr" )
      end
    end
    
    should "be able to pass through images etc for the ABR pages" do
      @browser.get "/phenotyping/MAKH/abr/MAKH10.1c_click.jpeg"
      assert( @browser.last_response.ok?, "Could not request '/phenotyping/MAKH/abr/MAKH10.1c_click.jpeg'." )
      
      @browser.get "/phenotyping/MAKH/abr/wibble.png"
      assert( !@browser.last_response.ok?, "Didn't get an error for '/phenotyping/MAKH/abr/wibble.png' - wtf?" )
      assert( @browser.last_response.status === 404, "Didn't get a 404 status for '/phenotyping/MAKH/abr/wibble.png' - wtf?" )
    end
    
    should "cope with asking for pages with data that is not there" do
      # TODO - will probably have to make the colony selection a touch 
      # more intelligent in the future... To pick a colony that has data,
      # but not for abr...
      @browser.get "/phenotyping/MAAE/abr/"
      assert( !@browser.last_response.ok?, "Didn't get an error for '/phenotyping/XXXX/abr/' - wtf?" )
      assert( @browser.last_response.status === 404, "Didn't get a 404 status for '/phenotyping/XXXX/abr/' - wtf?" )
      
      @browser.get "/phenotyping/MAAE/dexa-foo/"
      assert( !@browser.last_response.ok?, "Didn't get an error for '/phenotyping/XXXX/dexa/' - wtf?" )
      assert( @browser.last_response.status === 404, "Didn't get a 404 status for '/phenotyping/XXXX/dexa/' - wtf?" )
    end
  end
  
  def view_pheno_details_page( browser, colony_prefix, test )
    browser.get "/phenotyping/#{colony_prefix}/#{test}/"
    assert( browser.last_response.ok?, "Unable to make request to '/phenotyping/#{colony_prefix}/#{test}/'." )
    assert( browser.last_response.body.include?("<img"), "Phenotyping details page (/phenotyping/#{colony_prefix}/#{test}/) does not have any images." )
  end
  
  def check_abr_redirect( browser, colony_prefix )
    browser.get "/phenotyping/#{colony_prefix}/abr"
    browser.follow_redirect!
    assert( browser.last_response.ok?, "Redirect did not work for '/phenotyping/#{colony_prefix}/abr'." )
  end
end