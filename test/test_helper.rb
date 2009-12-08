begin
  require "shoulda"
rescue LoadError
  require "rubygems" unless ENV["NO_RUBYGEMS"]
  require "shoulda"
end

require "uri"
require "net/http"
require "json"
require "sinatra"
require "rdiscount"
require "mail"

require "active_support"
require "will_paginate/array"
require "will_paginate/view_helpers"

gem "biomart", ">=0.1.2"
require "biomart"

Dir[ File.dirname(__FILE__) + "/../lib/*.rb" ].each do |file|
  require file
end

##
## Some basic setup shared between the test suites
##

@@ms = Martsearch.new( File.dirname(__FILE__) + "/../config/config.json" )
