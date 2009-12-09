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

require "#{File.dirname(__FILE__)}/../lib/mock.rb"
require "#{File.dirname(__FILE__)}/../lib/dataset.rb"
require "#{File.dirname(__FILE__)}/../lib/index.rb"
require "#{File.dirname(__FILE__)}/../lib/martsearch.rb"

##
## Some basic setup shared between the test suites
##

@@ms = Martsearch.new( File.dirname(__FILE__) + "/../config/config.json" )
