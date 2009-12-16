
# Static routes for ABR data - this allows us to pull in the static 
# data generated for the ABR tests.
get "/phenotyping/:colony_prefix/abr" do
  redirect "#{BASE_URI}/phenotyping/#{params[:colony_prefix]}/abr/"
end

get "/phenotyping/:colony_prefix/abr/" do
  file = "#{@@pheno_abr_loc}/#{params[:colony_prefix]}/ABR/index.shtml"
  
  if File.exists?(file)
    html_text = ""
    
    File.open(file,"r") do |f|
      html_text = f.read
    end
    
    erb html_text
  else
    status 404
    erb :not_found
  end
end

get "/phenotyping/:colony_prefix/abr/*" do
  file = "#{@@pheno_abr_loc}/#{params[:colony_prefix]}/ABR/#{params[:splat][0]}"

  if File.exists?(file)
    content = nil
    File.open(file,"r") do |f|
      content = f.read
    end

    content_type MIME::Types.type_for(file)
    return content
  else
    status 404
    erb :not_found
  end
end

get "/phenotyping/:colony_prefix/:pheno_test/?" do
  setup_pheno_configuration
  
  @marker_symbol = nil
  @colony_prefix = params[:colony_prefix]
  @test_images   = JSON.parse( @@ms.cache.fetch("pheno_test_images") )[params[:colony_prefix]][params[:pheno_test]]
  @test          = nil
  
  search_data = nil
  search_data_from_cache = @@ms.cache.fetch("pheno_details_page_search:#{@colony_prefix}")
  
  if search_data_from_cache
    search_data = JSON.parse(search_data_from_cache)
  else
    search_data = @@ms.datasets_by_name[:phenotyping].dataset.search(
      :filters         => { "colony_prefix" => @colony_prefix },
      :attributes      => [ "pipeline", "marker_symbol" ],
      :process_results => true
    )
    @@ms.cache.write( "pheno_details_page_search:#{@colony_prefix}", search_data.to_json, :expires_in => 12.hours )
  end
  
  if search_data.nil?
    # Okay... so there is no data in the Biomart for this colony. 
    # So we can't display the marker_symbol and we have to guess 
    # at the pipeline...
    
    # Try MGP-Pipeline 1/2 first
    @test = Marshal.load( @@ms.cache.fetch("pheno_test_renders") )["mgp-pipeline-1-2"][params[:pheno_test]]
    
    # if that brings back nothing, try MouseGP
    if @test.nil?
      @test = Marshal.load( @@ms.cache.fetch("pheno_test_renders") )["mouse-gp"][params[:pheno_test]]
    end
  else
    pipeline = case search_data[0]["pipeline"]
    when "MouseGP" then "mouse-gp"
    when "P1/2"    then "mgp-pipeline-1-2"
    end
    
    @test          = Marshal.load( @@ms.cache.fetch("pheno_test_renders") )[pipeline][params[:pheno_test]]
    @marker_symbol = search_data[0]["marker_symbol"]
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

get "/phenotyping/heatmap" do
  setup_pheno_configuration
  
  heat_map_from_cache  = @@ms.cache.fetch("pheno_heatmap")
  @pheno_test_name_map = JSON.parse( @@ms.cache.fetch("pheno_test_names") )
  
  if heat_map_from_cache
    @heat_map = JSON.parse(heat_map_from_cache)
  else
    pheno_dataset       = @@ms.datasets_by_name[:phenotyping].dataset
    attributes_to_fetch = @@ms.datasets_by_name[:phenotyping].attributes
    attributes_to_fetch.push("marker_symbol")
    
    @heat_map = []
    results = pheno_dataset.search( :attributes => attributes_to_fetch, :process_results => true )
    
    results.sort_by { |r| r["marker_symbol"] }.each do |result|
      result["allele_name"] = @@ms.datasets_by_name[:phenotyping].fix_superscript_text_in_attribute(result["allele_name"])
      @heat_map.push(result)
    end
    
    @@ms.cache.write( "pheno_heatmap", @heat_map.to_json, :expires_in => 12.hours )
  end
  
  erb :"datasets/phenotyping/heatmap"
end
