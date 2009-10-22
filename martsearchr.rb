#!/usr/bin/env ruby -wKU

require "uri"
require "net/http"

require "rubygems"
require "sinatra"
require "json"

gem "biomart", ">0.1"
require "biomart"

Dir[ File.dirname(__FILE__) + '/lib/*.rb' ].each do |file|
  require file
end

configure do
  @@ms = Martsearch.new( "#{Dir.pwd}/config/config.json" )
end

helpers do
  # Implementation of Rails style partials.
  # Usage: partial :foo, options
  def partial(page, options={})
    erb page, options.merge!(:layout => false)
  end
end

before do
  headers "Content-Type" => "text/html; charset=utf-8"
  @config = @@ms.config
  
  @messages = {
    :status => [],
    :error  => []
  }
  
  unless @@ms.index.is_alive?
    @messages[:error].push("The search index is currently unavailable, please check back again soon.")
  end
end

get "/" do
  erb :main
end

get "/search" do
  @results = @@ms.search( params[:query], params[:page] )
  erb :search
end

get "/search/:query/:page" do
  @results = @@ms.search( params[:query], params[:page] )
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
