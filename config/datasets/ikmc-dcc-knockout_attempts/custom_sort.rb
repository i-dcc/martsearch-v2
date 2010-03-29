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
      "project_id"         => result["ikmc_project_id"],
      "status"             => result["status"],
      "marker_symbol"      => result["marker_symbol"],
      "ensembl_gene_id"    => result["ensembl_gene_id"],
      "igtc"               => result["igtc"],
      "imsr"               => result["imsr"],
      "mgi_gene_traps"     => result["mgi_gene_traps"],
      "targeted_mutations" => result["targeted_mutations"],
      "other_mutations"    => result["other_mutations"],
      "vector_available"   => "0",
      "escell_available"   => "0",
      "mouse_available"    => "0"
    }
  end
  
  project = result_data[ pipeline_name ]
  
  if pipeline_name == "TIGM"
    unless project.include? "cells" and project.include? "mice"
      project.update( { "cells" => [], "mice" => [] } )
    end
    
    if result["mouse_available"] and result["mouse_available"] == "1"
      project["mice"].push( result["ikmc_project_id"] )
    else
      project["cells"].push( result["ikmc_project_id"] )
    end
    
  else
    next if result['vector_available'] == '0'  \
         and result['escell_available'] == '0' \
         and result['mouse_available'] == 0
    
    if result['vector_available'] == '1'
      project['vector_available'] = '1'
      unless project['escell_available'] == '1' or project['mouse_available'] == '1'
        project['project_id'] = result['ikmc_project_id']
        project['status']     = result['status']
      end
    end
    
    if result['escell_available'] == '1'
      project['escell_available'] = '1'
      unless project['mouse_available'] == '1'
        project['project_id'] = result['ikmc_project_id']
        project['status']     = result['status']
      end
    end
    
    if result['mouse_available'] == '1'
      project['mouse_available'] = '1'
      project['project_id']      = result['ikmc_project_id']
      project['status']          = result['status']
    end
  end
end


##
##  Sort results: mice > cells > vectors
##

sorted_results.each do |key,sorted_result|
  projects_with_mice, projects_with_cells, projects_with_vectors = [], [], []
  
  sorted_result.sort.each do |pipeline_name, project_data|
    if pipeline_name == 'TIGM'
      if project_data['mice'].length > 0
        projects_with_mice.push( project_data )
      elsif project_data['cells'].length > 0
        projects_with_cells.push( project_data )
      end
    else
      if project_data['mouse_available'] == '1'
        projects_with_mice.push( project_data )
      elsif project_data['escell_available'] == '1'
        projects_with_cells.push( project_data )
      elsif project_data['vector_available'] == '1'
        projects_with_vectors.push( project_data )
      else
        sorted_result.delete( pipeline_name )
      end
    end
  end
  
  sorted_results[key].update({
    'projects' => (projects_with_mice + projects_with_cells + projects_with_vectors).freeze
  })
end

return sorted_results
