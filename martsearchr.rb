#!/usr/bin/env ruby -w

require "uri"
require "net/http"
require "cgi"

require "rubygems"
require "erubis"
require "json"
require "rdiscount"
require "mail"
require "active_support"
require "will_paginate/collection"
require "will_paginate/view_helpers"
require "rack/utils"

gem "sinatra", "=1.0.b"
require "sinatra"

gem "biomart", ">=0.1.5"
require "biomart"

MARTSEARCHR_PATH = File.expand_path(File.dirname(__FILE__))
require "#{MARTSEARCHR_PATH}/lib/mock.rb"
require "#{MARTSEARCHR_PATH}/lib/string.rb"
require "#{MARTSEARCHR_PATH}/lib/array.rb"
require "#{MARTSEARCHR_PATH}/lib/dataset.rb"
require "#{MARTSEARCHR_PATH}/lib/index.rb"
require "#{MARTSEARCHR_PATH}/lib/martsearch.rb"

# We're going to use the version number as a cache breaker 
# for the CSS and javascript code. Update with each release 
# of your portal (especially if you change the CSS or JS)!!!
PORTAL_VERSION = "0.0.7"

# Initialise the MartSearch object
@@ms = Martsearch.new( "#{MARTSEARCHR_PATH}/config/config.json" )
BASE_URI = @@ms.base_uri()

configure :production do
  not_found do
    # Email if this is a broken link within the portal
    @martsearch_error = false
    if request.env["HTTP_REFERER"]
      if request.env["HTTP_REFERER"].match(request.env["HTTP_HOST"])
        @martsearch_error = true
        if okay_to_send_emails?
          template_file = File.new("#{MARTSEARCHR_PATH}/views/not_found_email.erubis","r")
          template = Erubis::Eruby.new(template_file.read)
          template_file.close

          @@ms.send_email({
            :subject => "[MartSearch 404] '#{request.env["REQUEST_URI"]}'",
            :body    => template.result(binding)
          })
        end
      end
    end
    
    @request = request
    erubis :not_found
  end

  error do
    if okay_to_send_emails?
      template_file = File.new("#{MARTSEARCHR_PATH}/views/error_email.erubis","r")
      template = Erubis::Eruby.new(template_file.read)
      template_file.close

      @@ms.send_email({
       :subject => "[MartSearch Error] '#{request.env["sinatra.error"].message}'",
       :body    => template.result(binding)
      })
    end
    
    @request = request
    erubis :error
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
        buffer << erubis(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      erubis(:"#{template}", options)
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
      if link_options =~ /\/search|\/browse/
        # we've been given a search/browse link
        tmp  = link_options.split("?")
        opts = parse_query(tmp[1])
        url  = ""
        
        # Work out the url to use
        if link_options.match("/search")
          # First try RESTful style urls
          url = "#{BASE_URI}/search/#{opts["query"]}"
          if opts["page"] then url = "#{url}/#{opts["page"]}" end
          
          begin
            uri = URI.parse(url)
          rescue URI::InvalidURIError
            # If that goes pear shaped trying to do a weird query, 
            # use the standard ? interface and CGI::escape...
            url = "#{BASE_URI}/search?query=#{CGI::escape(opts["query"])}"
            if opts["page"] then url = "#{url}&page=#{opts["page"]}" end
          end
        elsif link_options.match("/browse")
          url = "#{BASE_URI}/browse/#{opts["field"]}/#{opts["query"]}"
          if opts["page"] then url = "#{url}/#{opts["page"]}" end
        end
        
        return url
      else
        link_options
      end
    end
  end
  
  # Load in any custom (per dataset) helpers
  @@ms.datasets.each do |ds|
    if ds.use_custom_view_helpers
      load "#{MARTSEARCHR_PATH}/config/datasets/#{ds.internal_name}/view_helpers.rb"
    end
  end
end

before do
  response["Content-Type"] = "text/html; charset=utf-8"
  
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
  erubis :main
end

get "/search/?" do
  if params.empty?
    redirect "#{BASE_URI}/"
  else
    @current    = "home"
    @page_title = "Search Results for '#{params[:query]}'"
    @results    = @@ms.search( params[:query], params[:page] )
    @data       = @@ms.search_data
    check_for_errors

    erubis :search
  end
end

["/search/:query/?", "/search/:query/:page/?"].each do |path|
  get path do
    @current    = "home"
    @page_title = "Search Results for '#{params[:query]}'"
    @results    = @@ms.search( params[:query], params[:page] )
    @data       = @@ms.search_data
    check_for_errors
    
    erubis :search
  end
end

get "/browse/?" do
  @current    = "browse"
  @page_title = "Browse"
  @results    = nil
  erubis :browse
end

["/browse/:field/:query/?", "/browse/:field/:query/:page?"].each do |path|
  get path do
    @current = "browse"
    browser  = @@ms.config["browsable_content"][params[:field]]
    if browser.nil?
      status 404
      erubis :not_found
    else
      
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
      
      erubis :browse
    end
  end
end

get "/about/?" do
  @current    = "about"
  @page_title = "About"
  erubis :about
end

get "/help/?" do
  @current    = "help"
  @page_title = "Help"
  erubis :help
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
    "jquery.tablesorter.css",
    "jquery-ui-1.7.2.redmond.css",
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
    "jquery-ui-1.7.2.min.js",
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
  Dir[ "#{MARTSEARCHR_PATH}/messages/*.html", "#{MARTSEARCHR_PATH}/messages/*.markdown" ].each do |file|
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

def okay_to_send_emails?
  okay_to_send_emails = true
  Dir[ "#{MARTSEARCHR_PATH}/tmp/*" ].each do |file|
    if file =~ /noemail/
      okay_to_send_emails = false
    end
  end
  return okay_to_send_emails
end

# Load in any custom (per dataset) routes
@@ms.datasets.each do |ds|
  if ds.use_custom_routes
    load "#{MARTSEARCHR_PATH}/config/datasets/#{ds.internal_name}/routes.rb"
  end
end
