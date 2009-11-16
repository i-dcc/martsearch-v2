#!/usr/bin/env ruby -wKU

require "uri"
require "net/http"

require "rubygems"
require "sinatra"
require "json"

require "active_support"
require "will_paginate/collection"
require "will_paginate/view_helpers"
require "rack/utils"

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
  
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << erb(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      erb(:"#{template}", options)
    end
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
      if link_options =~ /^\/search|\/browse/ and request.path_info =~ /^\/search|\/browse/
        # we've been given a pagination link
        tmp  = link_options.split("?")
        opts = parse_query(tmp[1])
        url  = "#"
        
        # Work out the url to use
        if tmp[0].match("/search")
          url = "/search/#{params["query"]}"
        elsif tmp[0].match("/browse")
          url = "/browse/#{params["field"]}/#{params["query"]}"
        end
        
        if opts["page"]
          return "#{url}/#{opts["page"]}"
        else
          return url
        end
      else
        link_options
      end
    end
  end
end

before do
  headers "Content-Type" => "text/html; charset=utf-8"
  @ms              = @@ms
  @current         = nil
  @page_title      = nil
  
  @messages = {
    :status => [],
    :error  => []
  }
  
  unless @@ms.index.is_alive?
    @messages[:error].push("The search index is currently unavailable, please check back again soon.")
  end
end

get "/?" do
  @current = "home"
  @sanger_counts = {
    :phenotyping       => @@ms.datasets_by_name[:phenotyping].dataset.count(),
    :mice              => @@ms.datasets_by_name[:kermits].dataset.count( :filters => { :mi_centre => "WTSI", :status => "Genotype Confirmed" } ),
    :escells           => @@ms.datasets_by_name[:htgt_targ].dataset.count( :filters => { :status => ["Mice - Genotype confirmed","Mice - Germline transmission","Mice - Microinjection in progress","ES Cells - Targeting Confirmed"] } ),
    :targ_vectors      => @@ms.datasets_by_name[:htgt_targ].dataset.count( :filters => { :status => ["Mice - Genotype confirmed","Mice - Germline transmission","Mice - Microinjection in progress","ES Cells - Targeting Confirmed","ES Cells - No QC Positives","ES Cells - Electroporation Unsuccessful","ES Cells - Electroporation in Progress","Vector - DNA Not Suitable for Electroporation","Vector Complete"] } ),
    :micer_clones      => @@ms.datasets_by_name[:bacs].dataset.count( :filters => { :library => "MICER" } ),
    :c57_bacs          => @@ms.datasets_by_name[:bacs].dataset.count( :filters => { :library => "C57Bl/6J" } ),
    :one_two_nine_bacs => @@ms.datasets_by_name[:bacs].dataset.count( :filters => { :library => "129S7" } )
  }
  erb :main
end

get "/search" do
  # Catch out empty search parameters - would otherwise cause infinite redirects
  if params[:query] =~ /^$/
    redirect "/"
  else
    if params[:page]
      redirect "/search/#{params[:query]}/#{params[:page]}"
    else
      redirect "/search/#{params[:query]}"
    end
  end
end

get "/search/" do
  # Catch out empty search parameters - would otherwise cause infinite redirects
  redirect "/"
end

["/search/:query/?", "/search/:query/:page/?"].each do |path|
  get path do
    @current    = "home"
    @page_title = "Search Results for '#{params[:query]}'"
    @results    = @@ms.search( params[:query], params[:page] )
    @data       = @@ms.search_data
    erb :search
  end
end

get "/browse/?" do
  @current    = "browse"
  @page_title = "Browse"
  @results    = nil
  erb :browse
end

["/browse/:field/:query/?", "/browse/:field/:query/:page?"].each do |path|
  get path do
    @current    = "browse"
    
    browser     = @@ms.config["browsable_content"][params[:field]]
    @page_title = "Browsing Data by '#{browser["display_name"]}'"
    
    # Extract our query parameter(s) for the browser...
    @solr_query = ""
    @browsing_by = {
      :field => browser["display_name"],
      :query => nil
    }
    browser["options"].each do |option|
      unless @browsing_by[:query]
        
        @solr_query  = nil
        exact_search = false
        search_term  = nil
        
        if option.is_a?(Array)
          if option[0].downcase === params[:query].downcase
            @browsing_by[:query] = option[0]
            @solr_query          = "#{browser["index_field"]}:#{option[1]}"
            search_term          = option[1]
          end
        elsif option.is_a?(Hash)
          if option["slug"].downcase == params[:query].downcase
            @browsing_by[:query] = option["text"]
            @solr_query          = "#{browser["index_field"]}:#{option["query"]}"
            search_term          = option["query"]
          end
        else
          if option.downcase === params[:query].downcase
            @browsing_by[:query] = option
            @solr_query          = "#{browser["index_field"]}:#{option}"
            search_term          = option
          end
        end
        
        # if the configuration doesnt already contain a grouped query 
        # make the search case insensitive (as we assume we are searching
        # on a solr string field - i.e. not interpreted in any way...)
        unless @solr_query.nil?
          unless @solr_query.match(/\)$/)
            if browser["exact_search"]
              @solr_query = "(#{browser["index_field"]}:#{search_term.downcase} OR #{browser["index_field"]}:#{search_term.upcase})"
            else
              @solr_query = "(#{browser["index_field"]}:#{search_term.downcase}* OR #{browser["index_field"]}:#{search_term.upcase}*)"
            end
          end
        end
        
      end
    end
  
    # Perform our search...
    @results    = @@ms.search( @solr_query, params[:page] )
    @data       = @@ms.search_data
  
    erb :browse
  end
end

get "/about/?" do
  @current    = "about"
  @page_title = "About"
  erb :about
end

get "/help/?" do
  @current    = "help"
  @page_title = "Help"
  erb :help
end

get "/css/dataset_styles.css" do
  content_type "text/css"
  @@ms.dataset_stylesheets
end
