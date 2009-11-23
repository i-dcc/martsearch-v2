require "rack"
require "rack/contrib"

use Rack::ETag
use Rack::ResponseCache, "#{File.dirname(__FILE__)}/tmp/static-cache"

require "martsearchr.rb"

set :environment, :production
set :run, false
set :logging, true

log = File.new("#{File.dirname(__FILE__)}/log/martsearch.log", "a+")
STDOUT.reopen(log)
STDERR.reopen(log)

require "logger"
configure do
  LOGGER = Logger.new("#{File.dirname(__FILE__)}/log/martsearch.log", "weekly") 
end

helpers do
  def logger
    LOGGER
  end
end

run Sinatra::Application
