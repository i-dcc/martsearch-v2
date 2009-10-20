begin
  require 'shoulda'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'shoulda'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')

require "uri"
require "net/http"
require "json"
require "sinatra"

require "lib/index"