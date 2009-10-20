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

