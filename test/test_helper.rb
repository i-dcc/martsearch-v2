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

gem "biomart", ">0.1"
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

@@datasources = []
@@config["datasources"].each do |ds|
  ds_conf_file = File.new("#{Dir.pwd}/config/datasources/#{ds["config"]}","r")
  ds_conf      = JSON.load(ds_conf_file)
  datasource   = Datasource.new( ds_conf, @http_client )
  
  if ds["custom_sort"]
    # If we have a custom sorting routine, use a Mock object
    # to override the sorting method.
    file = File.new("#{Dir.pwd}/config/datasources/#{ds["custom_sort"]}","r")
    buffer = file.read
    file.close
    datasource = Mock.method( datasource, :sort_results ) { eval(buffer) }
  end
  
  @@datasources.push( datasource )
end
