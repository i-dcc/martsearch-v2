begin
  require 'shoulda'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'shoulda'
end

require "uri"
require "net/http"
require "json"
require "sinatra"
require "biomart"

Dir[ File.dirname(__FILE__) + '/../lib/*.rb' ].each do |file|
  require file
end

##
## Some basic setup shared between the test suites
##

@@http_client = Net::HTTP
if ENV['http_proxy']
  proxy = URI.parse( ENV['http_proxy'] )
  @@http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
end

config_file = File.new( File.dirname(__FILE__) + "/../config/config.json", "r" )
@@config = JSON.load(config_file)

@@index = Index.new( @@config["index"], @@http_client )

@@datasets = []
@@config["datasets"].each do |ds|
  ds_conf_file = File.new( File.dirname(__FILE__) + "/../config/datasets/#{ds}/config.json","r")
  ds_conf      = JSON.load(ds_conf_file)
  @@datasets.push( Dataset.new( ds_conf, @@http_client ) )
end
