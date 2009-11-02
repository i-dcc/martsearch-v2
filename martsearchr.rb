#!/usr/bin/env ruby -wKU

require "uri"
require "net/http"

require "rubygems"
require "sinatra"
require "json"

require "active_support"
require "will_paginate/array"
require "will_paginate/view_helpers"

gem "biomart", ">=0.1.2"
require "biomart"

Dir[ File.dirname(__FILE__) + "/lib/*.rb" ].each do |file|
  require file
end

configure do
  @@ms = Martsearch.new( "#{Dir.pwd}/config/config.json" )
end

helpers do
  include WillPaginate::ViewHelpers
  
  def dataset_template( template_file, result_data )
    template = File.open( "#{Dir.pwd}/config/datasets/#{template_file}", "r" )
    erb      = ERB.new( template.read )
    return erb.result( binding )
  end
  
  def tag_options(options, escape = true)
    option_string = options.collect {|k,v| %{#{k}="#{v}"}}.join(" ")
    option_string = " " + option_string unless option_string.blank?
  end

  def content_tag(name, content, options, escape = true)
    tag_options = tag_options(options, escape) if options
    "<#{name}#{tag_options}>#{content}</#{name}>"
  end

  def link_to(text, link = nil, options = {})         
    link ||= text
    link = url_for(link)
    "<a href=\"#{link}\">#{text}</a>"
  end

  def url_for(link_options)
    case link_options
    when Hash
      path = link_options.delete(:path) || request.path_info
      params.delete("captures")
      path + "?" + build_query(params.merge(link_options))
    else
      link_options
    end
  end
  
end

before do
  headers "Content-Type" => "text/html; charset=utf-8"
  @ms = @@ms
  
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
  @data    = @@ms.search_data
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
