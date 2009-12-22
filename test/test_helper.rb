begin
  require "shoulda"
rescue LoadError
  require "rubygems" unless ENV["NO_RUBYGEMS"]
  require "shoulda"
end

require "uri"
require "net/http"
require "cgi"
require "json"
require "sinatra"
require "rdiscount"
require "mail"

require "active_support"
require "will_paginate/array"
require "will_paginate/view_helpers"

gem "biomart", ">=0.1.2"
require "biomart"

require "#{File.dirname(__FILE__)}/../lib/mock.rb"
require "#{File.dirname(__FILE__)}/../lib/dataset.rb"
require "#{File.dirname(__FILE__)}/../lib/index.rb"
require "#{File.dirname(__FILE__)}/../lib/martsearch.rb"
require "#{File.dirname(__FILE__)}/../lib/index_builder.rb"

##
## Some basic setup shared between the test suites
##

# Read in our config
conf_file = "#{File.dirname(__FILE__)}/../config/config.json"
conf_obj  = JSON.load( File.new( conf_file, "r" ) )

# Override the base URI for tests...
conf_obj["base_uri"] = ""

@@ms = Martsearch.new( conf_obj )
