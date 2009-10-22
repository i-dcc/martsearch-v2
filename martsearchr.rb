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
  @http_client = Net::HTTP
  if ENV['http_proxy']
    proxy = URI.parse( ENV['http_proxy'] )
    @http_client = Net::HTTP::Proxy( proxy.host, proxy.port )
  end

  config_file = File.new("#{Dir.pwd}/config/config.json","r")
  @@config    = JSON.load(config_file)

  @@index = Index.new( @@config["index"], @http_client ) # The index object
  
  @@datasources = []
  @@config["datasources"].each do |ds|
    ds_conf_file = File.new("#{Dir.pwd}/config/datasources/#{ds["config"]}","r")
    ds_conf      = JSON.load(ds_conf_file)
    datasource      = Datasource.new( ds_conf, @http_client )
    
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
  
  # Set-up a results stash - this will hold a structure of the 
  # retrieved data like...
  # {
  #   IndexDocUniqueKey => {
  #     "index"        => {}, # index results for this doc
  #     "datasource_name" => [], # array of sorted biomart data
  #     "datasource_name" => [], # array of sorted biomart data
  #   }
  # }
  @results = @@index.search( params[:query], params[:page] )
  
  @@datasources.each do |datasource|
    search_terms = @@index.grouped_terms[ datasource.joined_index_field ]
    mart_results = datasource.search( search_terms, @@index.current_results )
    datasource.add_to_results_stash( @results, mart_results )
  end
  
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
