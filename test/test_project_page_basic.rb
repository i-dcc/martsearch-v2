require "#{File.dirname(__FILE__)}/test_helper.rb"
require "sinatra"
require "rack/test"

set :environment, :test
set :logging, false
set :public, "#{File.dirname(__FILE__)}/../public"
set :views, "#{File.dirname(__FILE__)}/../views"

class ProjectPageBasic < Test::Unit::TestCase
  context "A MartSearch application" do
    setup do
      # Read in the config file
      conf_obj  = JSON.load( File.new( @@conf_file, "r" ) )
      
      # Copy the config file for safe keeping
      system("cp #{@@conf_file} #{@@conf_file}.orig")
      
      # Alter the conf_obj and save it in place of the original conf_file
      conf_obj["portal_url"] = "http://example.org/"
      File.open( @@conf_file, "w" ) { |f| f.write( conf_obj.to_json ) }
      
      require "#{File.dirname(__FILE__)}/../martsearchr.rb"
      
      # Create a 'noemail.txt' file in the /tmp dir so that we don't
      # send a million and one emails during the tests...
      system("touch #{File.dirname(__FILE__)}/../tmp/noemail.txt")
      
      # Now instanciate our MartSearch app
      @browser = Rack::Test::Session.new( Rack::MockSession.new( Sinatra::Application ) )
    end
    
    teardown do
      # Put our original conf file back
      system("mv #{@@conf_file}.orig #{@@conf_file}")
      
      # And clear the no email flag
      system("rm #{File.dirname(__FILE__)}/../tmp/noemail.txt")
    end

    PROJECT_IDS_TO_TEST = [ 35505, 39216, 42485 ]

    should "not crash and burn when we open a few project pages" do
      PROJECT_IDS_TO_TEST.each do |project_id|
        @browser.get "/project/#{project_id}"
        assert( @browser.last_response.ok?, "Unable to make request to '/project/#{project_id}'." )
        assert( @browser.last_response.body.include?(project_id.to_s), "The template does not include the project_id!" )
      end
    end
  end
end
