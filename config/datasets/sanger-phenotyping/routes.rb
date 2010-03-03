
##
## Static routes for ABR data - this allows us to pull in the static 
## data generated for the ABR tests.
##

get "/phenotyping/:colony_prefix/abr" do
  redirect "#{BASE_URI}/phenotyping/#{params[:colony_prefix]}/abr/"
end

get "/phenotyping/:colony_prefix/abr/" do
  file = "#{PHENO_ABR_LOC}/#{params[:colony_prefix]}/ABR/index.shtml"
  
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
  file = "#{PHENO_ABR_LOC}/#{params[:colony_prefix]}/ABR/#{params[:splat][0]}"

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

##
## Static route for homozygote-viability - uses different template from 
## other tests, so needs to be handled differently.
##

get "/phenotyping/:colony_prefix/homozygote-viability/?" do
  setup_pheno_configuration
  
  @marker_symbol = nil
  @colony_prefix = params[:colony_prefix]
  @test_data     = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-homviable_results") )[@colony_prefix]
  
  search_data = search_mart_by_colony_prefix(@colony_prefix)
  if search_data
    @marker_symbol = search_data[0]["marker_symbol"]
  end
  
  erb :"datasets/sanger-phenotyping/homviable_test_details"
end

##
## Routes for everything else
##

get "/phenotyping/:colony_prefix/:pheno_test/?" do
  setup_pheno_configuration
  
  @marker_symbol = nil
  @colony_prefix = params[:colony_prefix]
  @test_images   = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_images") )[params[:colony_prefix]][params[:pheno_test]]
  @test          = nil
  
  # Try to figure out our pipeline and marker_symbol
  search_data    = search_mart_by_colony_prefix(@colony_prefix)
  pipeline       = nil
  
  if search_data
    pipeline = case search_data[0]["pipeline"]
    when "MouseGP" then "mouse-gp"
    when "P1/2"    then "mgp-pipeline-1-2"
    end
    
    @marker_symbol = search_data[0]["marker_symbol"]
  end
  
  # Now fetch the test page renderer object.
  # If we still can't figure out the pipeline, we have to guess...
  test_conf = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_conf") )
  if pipeline.nil?
    # Try MGP-Pipeline 1/2 first
    @test = test_conf["mgp-pipeline-1-2"][params[:pheno_test]]
    
    # if that brings back nothing, try MouseGP
    if @test.nil? then @test = test_conf["mouse-gp"][params[:pheno_test]] end
  else
    @test = test_conf[pipeline][params[:pheno_test]]
  end
  
  if @test_images.nil? or @test.nil?
    @messages[:error].push({ :highlight => "Sorry, we could not find any phenotyping data for '#{params[:pheno_test]}' on '#{params[:colony_prefix]}'." })
    status 404
    erb :not_found
  else
    if @marker_symbol
      @page_title = "#{@marker_symbol} (#{@colony_prefix}): #{@test["name"]}"
    else
      @page_title = "#{@colony_prefix}: #{@test["name"]}"
    end
    erb :"datasets/sanger-phenotyping/test_details"
  end
end

get "/phenotyping/heatmap" do
  setup_pheno_configuration
  
  @page_title          = "Phenotyping Overview"
  heat_map_from_cache  = @@ms.cache.fetch("pheno_heatmap")
  @pheno_test_name_map = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_names") )
  
  if heat_map_from_cache
    @heat_map = JSON.parse(heat_map_from_cache)
  else
    pheno_dataset       = @@ms.datasets_by_name[:"sanger-phenotyping"].dataset
    attributes_to_fetch = @@ms.datasets_by_name[:"sanger-phenotyping"].attributes
    attributes_to_fetch.push("marker_symbol")
    
    @heat_map = []
    results = pheno_dataset.search( :attributes => attributes_to_fetch, :process_results => true )
    
    results.sort_by { |r| r["marker_symbol"] }.each do |result|
      result["allele_name"] = @@ms.datasets_by_name[:"sanger-phenotyping"].fix_superscript_text_in_attribute(result["allele_name"])
      @heat_map.push(result)
    end
    
    @@ms.cache.write( "pheno_heatmap", @heat_map.to_json, :expires_in => 12.hours )
  end
  
  erb :"datasets/sanger-phenotyping/heatmap"
end
