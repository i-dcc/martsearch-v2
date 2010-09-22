require "uri"
require "net/http"
require "cgi"
require "yaml"

require "rubygems"

gem "activesupport", "=2.3.8"
require 'active_support'

require "erubis"
require "json"
require "rdiscount"
require "mail"
require "will_paginate/collection"
require "will_paginate/view_helpers"
require "rack/utils"
require "rsolr"
require "tree"
require "sequel"

gem "sinatra", ">=1.0"
require "sinatra"

gem "biomart", ">=0.1.5"
require "biomart"

require "shoulda"

MARTSEARCHR_PATH = "#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{MARTSEARCHR_PATH}/lib/mock.rb"
require "#{MARTSEARCHR_PATH}/lib/string.rb"
require "#{MARTSEARCHR_PATH}/lib/array.rb"
require "#{MARTSEARCHR_PATH}/lib/dataset.rb"
require "#{MARTSEARCHR_PATH}/lib/index.rb"
require "#{MARTSEARCHR_PATH}/lib/ontology_term.rb"
require "#{MARTSEARCHR_PATH}/lib/martsearch.rb"
require "#{MARTSEARCHR_PATH}/lib/index_builder.rb"

##
## Some basic setup shared between the test suites
##

# Read in our config
@@conf_file = "#{MARTSEARCHR_PATH}/config/config.json"
conf_obj  = JSON.load( File.new( @@conf_file, "r" ) )

# Override the portal_url for tests...
conf_obj["portal_url"] = "http://example.org/"

@@ms = Martsearch.new( conf_obj )

# Setup the connection parameters for our OLS database...
env = ENV['RACK_ENV']
env = 'production' if env.nil?
dbc = YAML.load_file("#{MARTSEARCHR_PATH}/config/ols_database.yml")[env]
OLS_DB = Sequel.connect("mysql://#{dbc['username']}:#{dbc['password']}@#{dbc['host']}:#{dbc['port']}/#{dbc['database']}")
