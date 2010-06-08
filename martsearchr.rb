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
#require "yui/compressor"

gem "sinatra", ">=1.0"
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
PORTAL_VERSION    = "0.0.11"
DEFAULT_CSS_FILES = [
  "reset.css",
  "jquery.prettyPhoto.css",
  "jquery.tablesorter.css",
  "jquery.fontresize.css",
  "jquery-ui-1.8.1.redmond.css",
  "screen.css"
]
DEFAULT_JS_FILES  = [
  "jquery.qtip-1.0.js",
  "jquery.prettyPhoto.js",
  "jquery.tablesorter.js",
  "jquery.cookie.js",
  "jquery.fontResize.js",
  "jquery.scrollTo-1.4.2.js",
  "jquery-ui-1.8.1.min.js",
  "martsearchr.js"
]

# Initialise the MartSearch object
@@ms = Martsearch.new( "#{MARTSEARCHR_PATH}/config/config.json" )
BASE_URI = @@ms.base_uri()

def compress_js_and_css
  css_to_compress = ""
  js_to_compress  = ""
  
  DEFAULT_CSS_FILES.each do |file|
    file = File.new("#{MARTSEARCHR_PATH}/public/css/#{file}","r")
    css_to_compress << file.read
    file.close
  end
  
  DEFAULT_JS_FILES.each do |file|
    file = File.new("#{MARTSEARCHR_PATH}/public/js/#{file}","r")
    js_to_compress << file.read
    file.close
  end
  
  @@ms.datasets.each { |ds| css_to_compress << ds.stylesheet unless ds.stylesheet.nil? }
  @@ms.datasets.each { |ds| js_to_compress  << ds.javascript unless ds.javascript.nil? }
  
  #@@compressed_css = YUI::CssCompressor.new.compress(css_to_compress)
  #@@compressed_js  = YUI::JavaScriptCompressor.new.compress(js_to_compress)
  
  @@compressed_css = css_to_compress
  @@compressed_js  = js_to_compress
end

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
  
  compress_js_and_css
end

configure :staging do
  compress_js_and_css
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
  
  accept_request = true
  blocked_hosts  = ['picmole.com']
  
  blocked_hosts.each do |host|
    if \
         ( request.env["HTTP_FROM"] and request.env["HTTP_FROM"].match(host) ) \
      or ( request.env["HTTP_USER_AGENT"] and request.env["HTTP_USER_AGENT"].match(host) )
      accept_request = false
    end
  end
  
  halt 403, "go away!" unless accept_request
  
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
  @hide_side_search_form = true
  erubis :main
end

["/search/?", "/search/:query/?", "/search/:query/:page/?"].each do |path|
  get path do
    if params.empty?
      redirect "#{BASE_URI}/"
    else
      @current    = "home"
      @page_title = "Search Results for '#{params[:query]}'"
      @results    = @@ms.search( params[:query], params[:page] )
      @data       = @@ms.search_data
      check_for_errors

      if params[:wt] == "json"
        content_type "application/json"
        return @data.to_json
      else
        erubis :search
      end
    end
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

get "/index-status/:date?" do
    
  # Display a list of available reports
  if not params[:date]
    # Don't display a link when the file does not actually exist.
    file_paths = Dir.glob("#{MARTSEARCHR_PATH}/tmp/solr_document_xmls/*").select do |path|
      File.exists?("#{path}/coverage_report.html")
    end
    # Collect the dates - at the end of each path
    @report_dates = file_paths.collect { |path| path.split('/')[-1] }
    
    erubis :index_coverage_report_main
  
  # Find and display report for the given date
  else
    file = "#{MARTSEARCHR_PATH}/tmp/solr_document_xmls/#{params[:date]}/coverage_report.html"
    if File.exists?(file)
      erubis File.read( file )
    else
      status 404
      erubis :not_found
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
  content_type "text/css"
  compress_js_and_css unless @@compressed_css
  return @@compressed_css
end

get "/js/martsearch*.js" do
  content_type "text/javascript"
  compress_js_and_css unless @@compressed_js
  return @@compressed_js
end

get "/dataset-css/:dataset_name" do
  content_type "text/css"
  dataset_name = params[:dataset_name].sub(".css","")
  @@ms.datasets_by_name[ dataset_name.to_sym ].stylesheet
end

get "/dataset-js/:dataset_name" do
  content_type "text/javascript"
  dataset_name = params[:dataset_name].sub(".js","")
  @@ms.datasets_by_name[ dataset_name.to_sym ].javascript
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

load "#{MARTSEARCHR_PATH}/project_report.rb"
