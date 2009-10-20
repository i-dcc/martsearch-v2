#!/usr/bin/env ruby -wKU

require "uri"
require "net/http"

require "rubygems"
require "sinatra"
require "json"

require "lib/index"

##
## Set up MartSearch
##

def init
  @http_client = Net::HTTP
  if ENV['http_proxy']
    proxy = URI.parse( ENV['http_proxy'] )
    @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
  end

  config_file = File.new("#{Dir.pwd}/config/config.json","r")
  @@config    = JSON.load(config_file)

  @@index = Index.new( @@config["index"], @http_client ) # The index object
end

init()

##
## Define our Sinatra app
##

helpers do
  # Implementation of Rails style partials.
  # Usage: partial :foo, options
  def partial(page, options={})
    erb page, options.merge!(:layout => false)
  end
end

before do
  headers "Content-Type" => "text/html; charset=utf-8"
  @config = @@config
  
  @messages = {
    :status => [],
    :error  => []
  }
  
  unless @@index.is_alive?
    @messages[:error].push("The search index is currently unavailable, please check back again soon.")
  end
end

get "/" do
  erb :main
end

get "/search" do
  @@index.search( params[:query], params[:page] )
  
  @results = @@index.grouped_terms
  erb :search
end

get "/browse" do
  erb :browse
end

get "/about" do
  erb :about
end

get "/help" do
  erb :help
end
