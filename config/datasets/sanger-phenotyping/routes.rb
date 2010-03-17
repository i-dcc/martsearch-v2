
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
    html_text   = ""
    @page_title = "#{params[:colony_prefix]}: Auditory Brainstem Response (ABR)"
    
    search_data = search_mart_by_colony_prefix(@colony_prefix)
    unless search_data.empty?
      @marker_symbol = search_data[0]["marker_symbol"]
      @page_title = "#{@marker_symbol} (#{params[:colony_prefix]}): Auditory Brainstem Response (ABR)"
    end
    
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
## Static route for homozygote-viability / fertility - they use different 
## templates so need to be handled differently.
##

get "/phenotyping/:colony_prefix/homozygote-viability/?" do
  setup_pheno_configuration
  @test_data = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-homviable_results") )[params[:colony_prefix]]
  
  if @test_data
    @test_data     = @test_data[0]
    @marker_symbol = nil
    @colony_prefix = params[:colony_prefix]
    @page_title    = "#{@colony_prefix}: Homozygote Viability"

    search_data = search_mart_by_colony_prefix(@colony_prefix)
    unless search_data.empty?
      @marker_symbol = search_data[0]["marker_symbol"]
      @page_title = "#{@marker_symbol} (#{@colony_prefix}): Homozygote Viability"
    end

    erb :"datasets/sanger-phenotyping/homviable_test_details"
  else
    @messages[:error].push({ :highlight => "Sorry, we could not find any Homozygote Viability data for '#{params[:colony_prefix]}'." })
    status 404
    erb :not_found
  end
end

get "/phenotyping/:colony_prefix/fertility/?" do
  setup_pheno_configuration
  
  if JSON.parse( @@ms.cache.fetch("sanger-phenotyping-fertility_results_lookup") )[params[:colony_prefix]]
    @marker_symbol = nil
    @colony_prefix = params[:colony_prefix]
    @mating_data   = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-fertility_results_#{@colony_prefix}") )
    @page_title    = "#{@colony_prefix}: Fertility"

    search_data = search_mart_by_colony_prefix(@colony_prefix)
    unless search_data.empty?
      @marker_symbol = search_data[0]["marker_symbol"]
      @page_title = "#{@marker_symbol} (#{@colony_prefix}): Fertility"
    end
    
    erb :"datasets/sanger-phenotyping/fertility_test_details"
  else
    @messages[:error].push({ :highlight => "Sorry, we could not find any Fertility data for '#{params[:colony_prefix]}'." })
    status 404
    erb :not_found
  end
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
  
  unless search_data.empty?
    pipeline = case search_data[0]["pipeline"]
    when "Mouse GP" then "mouse-gp"
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
  @heat_map            = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-heatmap") )
  @pheno_test_name_map = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_names") )
  
  erb :"datasets/sanger-phenotyping/heatmap"
end
