require "#{File.dirname(__FILE__)}/test_helper.rb"
require "sinatra"
require "rack/test"

set :environment, :test
set :logging, false
set :public, "#{File.dirname(__FILE__)}/../public"
set :views, "#{File.dirname(__FILE__)}/../views"

class ReportedCrashesTest < Test::Unit::TestCase
  context "The Sanger Mouse Portal" do
    setup do
      # Read in the config file
      conf_obj  = JSON.load( File.new( @@conf_file, "r" ) )
      
      # Copy the config file for safe keeping
      system("cp #{@@conf_file} #{@@conf_file}.orig")
      
      # Alter the conf_obj and save it in place of the original conf_file
      conf_obj["portal_url"] = "http://example.org/"
      File.open( @@conf_file, "w" ) { |f| f.write( conf_obj.to_json ) }
      
      require "#{File.dirname(__FILE__)}/../martsearchr.rb"
      
      # Now instanciate our MartSearch app
      @browser = Rack::Test::Session.new( Rack::MockSession.new( Sinatra::Application ) )
    end
    
    teardown do
      # Put our original conf file back
      system("mv #{@@conf_file}.orig #{@@conf_file}")
    end

    reported_bad_urls = [
      '/browse/chromosome/7/305',
      '/browse/marker-symbol/h/13',
      '/browse/chromosome/11/249'
    ]
    
    reported_bad_urls.each do |url|
      should "not crash on #{url}" do
        @browser.get url
        assert( @browser.last_response.ok?, "Unable to make successful request to '#{url}'." )
      end
    end
  end
end
