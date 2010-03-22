require "uri"
require "net/http"
require "cgi"

require "rubygems"
require "erubis"
require "json"
require "rdiscount"
require "mail"
require "active_support"
require "will_paginate/collection"
require "will_paginate/view_helpers"
require "rack/utils"
require "rsolr"

gem "sinatra", "=1.0.b"
require "sinatra"

gem "biomart", ">=0.1.5"
require "biomart"

require "shoulda"

require "#{File.dirname(__FILE__)}/../lib/mock.rb"
require "#{File.dirname(__FILE__)}/../lib/string.rb"
require "#{File.dirname(__FILE__)}/../lib/array.rb"
require "#{File.dirname(__FILE__)}/../lib/dataset.rb"
require "#{File.dirname(__FILE__)}/../lib/index.rb"
require "#{File.dirname(__FILE__)}/../lib/martsearch.rb"
require "#{File.dirname(__FILE__)}/../lib/index_builder.rb"

##
## Some basic setup shared between the test suites
##

# Read in our config
@@conf_file = "#{File.dirname(__FILE__)}/../config/config.json"
conf_obj  = JSON.load( File.new( @@conf_file, "r" ) )

# Override the portal_url for tests...
conf_obj["portal_url"] = "http://example.org/"

@@ms = Martsearch.new( conf_obj )
