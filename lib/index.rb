# Error class for when an index search misbehaves
class IndexSearchError < StandardError; end

# Error class for when the index is unavailable
class IndexUnavailableError < StandardError; end

# Class representation for a Solr Index service used 
# in MartSearch.
class Index
  attr_reader :primary_field, :docs_per_page, :grouped_terms
  attr_accessor :url, :ordered_results, :current_results, :current_results_total, :current_page
  
  def initialize( conf, client )
    # Schema specific details...
    @schema_name     = conf["schema_name"]
    @primary_field   = conf["schema"]["unique_key"]
    @sort_results_by = conf["sort_results_by"]
    @schema          = conf["schema"]
    
    # Location/search details...
    @url             = conf["url"]
    @docs_per_page   = conf["docs_per_page"]
    
    # Connection client...
    @http_client   = client
    
    # Placeholders
    @ordered_results       = []
    @current_results       = {}
    @current_results_total = 0
    @current_page          = 1
    @grouped_terms         = {}
    
  end
  
  # Simple heartbeat function to determine if the index 
  # service is alive. Returns true/false.
  def is_alive?
    res = @http_client.get_response( URI.parse("#{@url}/admin/ping?wt=ruby") )
    
    if res.code != "200"
      raise IndexUnavailableError, "Index HTTP error #{res.code}"
    else
      data = eval(res.body)
      if data["status"] === "OK"
        return true
      else
        raise IndexUnavailableError, "Index Error: #{res.body}"
      end
    end
  end
  
  # Function to submit a query to the search index and 
  # return the processed response object.
  def search( query, page=nil )
    
    # Reset all of our stored variables
    @ordered_results       = []
    @current_results       = {}
    @grouped_terms         = {}
    @current_results_total = 0
    @current_page          = 1
    
    # Calculate the start page
    start_doc = 0
    if page and ( Integer(page) > 1 )
      start_doc = ( Integer(page) - 1 ) * @docs_per_page
    end
    
    data = index_request(
      {
        "q"     => query,
        "sort"  => @sort_results_by,
        "start" => start_doc,
        "rows"  => @docs_per_page,
        "hl"    => true,
        "hl.fl" => '*'
      }
    )
    
    if start_doc === 0
      @current_page = 1
    else
      @current_page = ( start_doc / @docs_per_page ) + 1
    end
    
    @current_results_total = data["response"]["numFound"]
    
    data["response"]["docs"].each do |doc|
      @current_results[ doc[ @primary_field ] ] = {
        "index"               => doc,
        "search_explaination" => data["highlighting"][ doc[ @primary_field ] ]
      }
      @ordered_results.push( doc[ @primary_field ] )
    end
    
    # Process and cache these results ready for searching the marts
    @grouped_terms = grouped_query_terms( @current_results )
    
    return @current_results
  end
  
  # Function to perform a query against the index and 
  # return the processed results.  This is called quick_search 
  # as it bypasses all of the default martsearch post-search 
  # processing actions.
  def quick_search( query, page=nil )
    # Calculate the start page
    start_doc = 0
    if page and ( Integer(page) > 1 )
      start_doc = ( Integer(page) - 1 ) * @docs_per_page
    end
    
    data = index_request(
      {
        "q"     => query,
        "sort"  => @sort_results_by,
        "start" => start_doc,
        "rows"  => @docs_per_page
      }
    )
    return data["response"]["docs"]
  end
  
  # Function to submit a query to the search index, and 
  # return back the number of docs/results found.
  def count( query )
    data = index_request({ "q" => query })
    return data["response"]["numFound"]
  end
  
  private
  
    # Helper function to process the results of the JSON 
    # response and extract the fields from each doc into 
    # a hash (which is returned)
    def grouped_query_terms( results )
      grouped_terms = {}
    
      unless results.empty?
        results.each do |primary_field,results_stash|
          results_stash["index"].each do |field,value|
            grouped_terms_for_field = grouped_terms[field]

            unless grouped_terms_for_field 
              grouped_terms[field]    = []
              grouped_terms_for_field = grouped_terms[field]
            end
            
            if value.is_a?(Array)
              value.each do |val|
                grouped_terms_for_field.push( val )
              end
            else
              grouped_terms_for_field.push( value )
            end
          end
        end
      
        grouped_terms.each do |field,values|
          grouped_terms[field] = values.uniq
        end
      end
      
      return grouped_terms
    end
    
    # Utility function to handle the search/count requsets 
    # to the index.
    def index_request( params={} )
      res = @http_client.post_form( URI.parse("#{self.url}/select"), params.update({ "wt" => "ruby" }) )

      if res.code.to_i != 200
        raise IndexSearchError, "Index Search Error: #{res.body}"
      else
        return eval(res.body)
      end
    end
  
end