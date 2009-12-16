#!/usr/bin/env ruby -wKU

require "uri"
require "net/http"

require "rubygems"
require "sinatra"
require "json"
require "rdiscount"
require "mail"

require "active_support"
require "will_paginate/collection"
require "will_paginate/view_helpers"
require "rack/utils"

gem "biomart", ">=0.1.3"
require "biomart"

Dir[ File.dirname(__FILE__) + "/lib/*.rb" ].each do |file|
  require file
end

# We're going to use the version number as a cache breaker 
# for the CSS and javascript code. Update with each release 
# of your portal (especially if you change the CSS or JS)!!!
PORTAL_VERSION = "0.0.1"

# Initialise the MartSearch object
@@ms = Martsearch.new( "#{File.dirname(__FILE__)}/config/config.json" )
BASE_URI = @@ms.config["base_uri"]

configure :production do
  not_found do
    # Email if this is a broken link within the portal
    @martsearch_error = false
    if request.env["HTTP_REFERER"]
      if request.env["HTTP_REFERER"].match(request.env["HTTP_HOST"])
        @martsearch_error = true
        
        template_file = File.new("#{File.dirname(__FILE__)}/views/not_found_email.erb","r")
        template = ERB.new(template_file.read)
        template_file.close
        
        @@ms.send_email({
          :subject => "[MartSearch 404] '#{request.env["REQUEST_PATH"]}'",
          :body    => template.result(binding)
        })
      end
    end
    
    @request = request
    erb :not_found
  end

  error do
    template_file = File.new("#{File.dirname(__FILE__)}/views/error_email.erb","r")
    template = ERB.new(template_file.read)
    template_file.close
    
    @@ms.send_email({
     :subject => "[MartSearch Error] '#{request.env["sinatra.error"].message}'",
     :body    => template.result(binding)
    })
    
    @request = request
    erb :error
  end
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
      if link_options =~ /\/search|\/browse/ and request.path_info =~ /\/search|\/browse/
        # we've been given a pagination link
        tmp  = link_options.split("?")
        opts = parse_query(tmp[1])
        url  = "#"
        
        # Work out the url to use
        if tmp[0].match("/search")
          url = "#{BASE_URI}/search/#{params["query"]}"
        elsif tmp[0].match("/browse")
          url = "#{BASE_URI}/browse/#{params["field"]}/#{params["query"]}"
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
  
  load "#{Dir.pwd}/config/datasets/phenotyping/view_helpers.rb"
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
  
  check_for_messages
end

get "/?" do
  @current = "home"
  
  sanger_counts_from_cache = @@ms.cache.fetch("sanger_counts")
  if sanger_counts_from_cache
    @sanger_counts = JSON.parse(sanger_counts_from_cache)
  else
    @sanger_counts = {
      "phenotyping"       => @@ms.datasets_by_name[:phenotyping].dataset.count(),
      "mice"              => @@ms.datasets_by_name[:kermits].dataset.count( :filters => { :mi_centre => "WTSI", :status => "Genotype Confirmed" } ),
      "escells"           => @@ms.datasets_by_name[:htgt_targ].dataset.count( :filters => { :status => ["Mice - Genotype confirmed","Mice - Germline transmission","Mice - Microinjection in progress","ES Cells - Targeting Confirmed"] } ),
      "targ_vectors"      => @@ms.datasets_by_name[:htgt_targ].dataset.count( :filters => { :status => ["Mice - Genotype confirmed","Mice - Germline transmission","Mice - Microinjection in progress","ES Cells - Targeting Confirmed","ES Cells - No QC Positives","ES Cells - Electroporation Unsuccessful","ES Cells - Electroporation in Progress","Vector - DNA Not Suitable for Electroporation","Vector Complete"] } ),
      "micer_clones"      => @@ms.datasets_by_name[:bacs].dataset.count( :filters => { :library => "MICER" } ),
      "c57_bacs"          => @@ms.datasets_by_name[:bacs].dataset.count( :filters => { :library => "C57Bl/6J" } ),
      "one_two_nine_bacs" => @@ms.datasets_by_name[:bacs].dataset.count( :filters => { :library => "129S7" } )
    }
    @@ms.cache.write( "sanger_counts", @sanger_counts.to_json, :expires_in => 3.hours )
  end
  
  erb :main
end

get "/search" do
  # Catch out empty search parameters - would otherwise cause infinite redirects
  if params[:query]
    if params[:page]
      redirect "#{BASE_URI}/search/#{params[:query]}/#{params[:page]}"
    else
      redirect "#{BASE_URI}/search/#{params[:query]}"
    end
  else
    redirect "#{BASE_URI}/"
  end
end

get "/search/" do
  # Catch out empty search parameters - would otherwise cause infinite redirects
  redirect "#{BASE_URI}/"
end

["/search/:query/?", "/search/:query/:page/?"].each do |path|
  get path do
    @current    = "home"
    @page_title = "Search Results for '#{params[:query]}'"
    @results    = @@ms.search( params[:query], params[:page] )
    @data       = @@ms.search_data
    check_for_errors
    
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
    check_for_errors
    
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

get "/clear_cache/?" do
  @@ms.cache.delete_matched( Regexp.new(".*") )
  redirect "#{BASE_URI}/"
end

get "/css/martsearch*.css" do
  css_text = ""
  css_files = [
    "reset.css",
    "jquery.prettyPhoto.css",
    "screen.css"
  ]
  
  css_files.each do |file|
    css_text << "\n /* #{file} */ \n\n"
    file = File.new("#{Dir.pwd}/public/css/#{file}","r")
    css_text << file.read
    file.close
  end
  
  css_text << "\n /* DATASET CUSTOM CSS */ \n\n"
  css_text << @@ms.dataset_stylesheets
  
  content_type "text/css"
  return css_text
end

get "/js/martsearch*.js" do
  js_text = ""
  js_files = [
    "jquery-plugins.min.js",
    "martsearchr.js"
  ]
  
  js_files.each do |file|
    js_text << "\n /* #{file} */ \n\n"
    file = File.new("#{Dir.pwd}/public/js/#{file}","r")
    js_text << file.read
    file.close
  end
  
  js_text << "\n // DATASET CUSTOM JS \n\n"
  js_text << @@ms.dataset_javascripts
  
  content_type "text/javascript"
  return js_text
end

def check_for_errors
  unless @@ms.index.is_alive?
    @messages[:error].push({ :highlight => "The search index is currently unavailable, please check back again soon." })
  end
  
  @@ms.errors.each do |error|
    @messages[:error].push(error)
  end
end

def check_for_messages
  pwd = File.dirname(__FILE__)
  Dir[ "#{pwd}/messages/*.html", "#{pwd}/messages/*.markdown" ].each do |file|
    case file
    when /html/
      html = File.new( file, "r" )
      @messages[:status].push(html.read)
      html.close
    when /markdown/
      md = File.new( file, "r" )
      @messages[:status].push( RDiscount.new(md.read).to_html )
      md.close
    end
  end
end

load "#{Dir.pwd}/config/datasets/phenotyping/routes.rb"