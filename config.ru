require "rack"
require "rack/contrib"

use Rack::ResponseCache, "#{File.dirname(__FILE__)}/tmp/static-cache"
  
require "martsearchr.rb"

set :environment, :production
set :run, false

run Sinatra::Application
