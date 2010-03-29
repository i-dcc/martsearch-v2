sorted_results = {}

@current_search_results.each do |result|
  # Skip empty results
  next if result['ikmc_project'].nil? or result['ikmc_project_id'].nil?
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  pipeline_name = result["ikmc_project"]
  
  # Only keep one result per pipeline
  unless result_data[ pipeline_name ]
    result_data[ pipeline_name ] = {
      "pipeline_name"      => pipeline_name,
      "mgi_accession_id"   => result["mgi_accession_id"],
      "marker_symbol"      => result["marker_symbol"],
      "ensembl_gene_id"    => result["ensembl_gene_id"],
      "igtc"               => result["igtc"],
      "imsr"               => result["imsr"],
      "mgi_gene_traps"     => result["mgi_gene_traps"],
      "targeted_mutations" => result["targeted_mutations"],
      "other_mutations"    => result["other_mutations"],
      "vector_available"   => "0",
      "escell_available"   => "0",
      "mouse_available"    => "0",
      "cells"              => [],
      "mice"               => []
    }
  end
  
  project = result_data[ pipeline_name ]
  
  if pipeline_name == "TIGM"
    if result["mouse_available"] and result["mouse_available"] == "1"
      project["mice"].push( result["ikmc_project_id"] )
    else
      project["cells"].push( result["ikmc_project_id"] )
    end
  end
end

##
##  Sort results: mice > cells > vectors
##

results_to_return = {}

sorted_results.each do |joined_biomart_key,results|
  projects_with_mice, projects_with_cells, projects_with_vectors = [], [], []
  
  results.each do |pipeline_name, pipeline_data|
    if pipeline_name == 'TIGM'
      if pipeline_data['mice'].size > 0
        projects_with_mice.push( pipeline_data )
      elsif pipeline_data['cells'].size > 0
        projects_with_cells.push( pipeline_data )
      end
    end
  end
  
  results_to_return[joined_biomart_key] = (projects_with_mice + projects_with_cells + projects_with_vectors).freeze
end

return results_to_return
