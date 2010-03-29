require "#{File.expand_path(File.dirname(__FILE__))}/config/datasets/europhenome-biomart/view_helpers.rb"

sorted_results = {}

@current_search_results.each do |result|
  next unless result["gene_id"] and result["europhenome_id"]
  
  if sorted_results[ result[ @joined_biomart_attribute ] ].nil?
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  
  het_hom = case result['zygosity'].to_s
  when "1" then "Hom"
  when "0" then "Het"
  end
  
  if sorted_results[ result[ @joined_biomart_attribute ] ][ "#{result['europhenome_id']}-#{het_hom}" ].nil?
    sorted_results[ result[ @joined_biomart_attribute ] ][ "#{result['europhenome_id']}-#{het_hom}" ] = {
      "europhenome_id" => result["europhenome_id"],
      "line_name"      => result["line_name"],
      "zygosity"       => het_hom,
      "allele_id"      => result["allele_id"],
      "allele_name"    => result["allele_name"],
      "emma_id"        => result["emma_id"],
      "escell_clone"   => result["epd_id"],
      "stocklist_id"   => result["stocklist_id"],
      "pipeline_data"  => {}
    }
  end
  
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ][ "#{result['europhenome_id']}-#{het_hom}" ]
  
  # Process and store the result data...
  
  pipeline_name = nil
  test_eslim_id = result["parameter_eslim_id"][0,( result["parameter_eslim_id"].size - 4 )]
  
  europhenome_pipelines().each do |pipeline,ids|
    if ids.include?(test_eslim_id) then pipeline_name = pipeline end
  end
  
  unless pipeline_name.nil?
    unless result_data["pipeline_data"][test_eslim_id]
      result_data["pipeline_data"][test_eslim_id] = {
        "is_male_signifigant"   => nil,
        "is_female_signifigant" => nil,
        "parameters"            => {}
      }
    end
    
    if result_data["pipeline_data"][test_eslim_id]["parameters"][ result["parameter_eslim_id"] ].nil?
      result_data["pipeline_data"][test_eslim_id]["parameters"][ result["parameter_eslim_id"] ] = {
        "is_male_signifigant"   => nil,
        "is_female_signifigant" => nil,
        "parameter_eslim_id"    => result["parameter_eslim_id"],
        "parameter_name"        => result["parameter_name"],
        "results"               => []
      }
    end
    
    result_data["pipeline_data"][test_eslim_id]["parameters"][ result["parameter_eslim_id"] ]["results"].push({
      "sex"                 => result["sex"],
      "significance"        => result["significance"],
      "effect_size"         => result["effect_size"],
      "mp_term"             => result["mp_term"],
      "mp_term_name"        => result["mp_term_name"]
    })
  end
end

# Now that we have all of the data, run over the test headers and decide, 
# whether we should mark it up as interesting or not...

significance_cutoff = 0.0001

sorted_results.each do |mgi_accession_id,europhenome_data|
  europhenome_data.each do |europh_id_zyg,line_data|
    line_data["pipeline_data"].each do |pipeline,pipeline_data|
      pipeline_data["parameters"].each do |parameter_name,parameter|
        parameter["results"].each do |result|
          
          if result["significance"].to_f > significance_cutoff 
            if result["sex"] == "Male"
              pipeline_data["is_male_signifigant"] = true
              parameter["is_male_signifigant"]     = true
            else
              pipeline_data["is_female_signifigant"] = true
              parameter["is_female_signifigant"]     = true
            end
          else
            if result["sex"] == "Male"
              pipeline_data["is_male_signifigant"] = false
              parameter["is_male_signifigant"]     = false
            else
              pipeline_data["is_female_signifigant"] = false
              parameter["is_female_signifigant"]     = false
            end
          end
          
        end
      end
    end
  end
end

return sorted_results
