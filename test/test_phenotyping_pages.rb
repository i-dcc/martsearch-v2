require "#{File.dirname(__FILE__)}/test_helper.rb"
require "sinatra"
require "rack/test"

set :environment, :test
set :logging, false
set :public, "#{File.dirname(__FILE__)}/../public"
set :views, "#{File.dirname(__FILE__)}/../views"

class PhenotypingPagesTest < Test::Unit::TestCase
  context "The Sanger Mouse Portal Phenotyping Section" do
    setup do
      # Read in the config file
      conf_obj  = JSON.load( File.new( @@conf_file, "r" ) )
      
      # Copy the config file for safe keeping
      system("cp #{@@conf_file} #{@@conf_file}.orig")
      
      # Alter the conf_obj and save it in place of the original conf_file
      conf_obj["base_uri"] = ""
      File.open( @@conf_file, "w" ) { |f| f.write( conf_obj.to_json ) }
      
      require "#{File.dirname(__FILE__)}/../martsearchr.rb"
      
      # Now instanciate our MartSearch app
      @browser = Rack::Test::Session.new( Rack::MockSession.new( Sinatra::Application ) )
    end
    
    teardown do
      # Put our original conf file back
      File.delete(@@conf_file)
      system("mv #{@@conf_file}.orig #{@@conf_file}")
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
