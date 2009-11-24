require "rack"
require "rack/contrib"
require "martsearchr.rb"

use Rack::ETag

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
