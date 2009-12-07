
# Static route for testing Neils pages with the portal.  In production 
# this will be handled by a bit of apache proxying and url rewriting.
get "/phenotyping/:colony_prefix/abr/?" do
  html_text = ""
  
  File.open("#{@@pheno_abr_loc}/#{params[:colony_prefix]}/ABR/index.shtml", "r") do |f|
    html_text = f.read
  end
  
  return html_text
end

get "/phenotyping/:colony_prefix/:pheno_test/?" do
  setup_pheno_configuration
  
  @marker_symbol = nil
  @colony_prefix = params[:colony_prefix]
  @test_images   = JSON.parse( @@ms.cache.fetch("pheno_test_images") )[params[:colony_prefix]][params[:pheno_test]]
  @test          = nil
  
  results        = @@ms.search( "colony_prefix:#{@colony_prefix}", 1 )
  search_data    = @@ms.search_data
  
  if search_data.nil?
    
    # Okay... so there is no data in the Biomart or search engine for 
    # this colony.  So we can't display the marker_symbol and we have to 
    # guess at the pipeline...
    
    # Try MGP-Pipeline 1/2 first
    @test = Marshal.load( @@ms.cache.fetch("pheno_test_renders") )["mgp-pipeline-1-2"][params[:pheno_test]]
    
    # if that brings back nothing, try MouseGP
    if @test.nil?
      @test = Marshal.load( @@ms.cache.fetch("pheno_test_renders") )["mouse-gp"][params[:pheno_test]]
    end
    
  else
    if search_data.keys.size != 1 or search_data[search_data.keys[0]]["phenotyping"].size != 1
      @message[:error].push({ :highlight => "Sorry, we are unable to display phenotyping test data (#{params[:pheno_test]}) for this colony (#{params[:colony_prefix]}) due to ambiguities in our current data structure.  Please contact <a href='mailto:mouseportal@sanger.ac.uk'>mouseportal@sanger.ac.uk</a> with this error so that we can fix this for you." })
      erb :error
    else
      page_data = search_data[search_data.keys[0]]
      
      pipeline = case page_data["phenotyping"][0]["pipeline"]
      when "MouseGP" then "mouse-gp"
      when "P1/2"    then "mgp-pipeline-1-2"
      end
      
      @test          = Marshal.load( @@ms.cache.fetch("pheno_test_renders") )[pipeline][params[:pheno_test]]
      @marker_symbol = page_data["index"]["symbol"]
    end
  end
  
  if @test_images.nil? or @test.nil?
    @messages[:error].push({ :highlight => "Sorry, we could not find any phenotyping data for '#{params[:pheno_test]}' on '#{params[:colony_prefix]}'." })
    status 404
    erb :not_found
  else
    if @marker_symbol
      @page_title = "#{@marker_symbol} (#{@colony_prefix}): #{@test.name}"
    else
      @page_title = "#{@colony_prefix}: #{@test.name}"
    end
    erb :"datasets/phenotyping/_test_details"
  end
end