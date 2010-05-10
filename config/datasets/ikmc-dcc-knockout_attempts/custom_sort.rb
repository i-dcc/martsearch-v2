sorted_results = {}

@current_search_results.each do |result|
  # Skip empty results
  next if result['ikmc_project'].nil? or result['ikmc_project_id'].nil?
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  pipeline_name = result["ikmc_project"]
  
  unless result_data[ pipeline_name ]
    result_data[ pipeline_name ] = {
      "pipeline_name"      => pipeline_name,
      "mgi_accession_id"   => result["mgi_accession_id"],
      "status"             => result["status"],
      "marker_symbol"      => result["marker_symbol"],
      "ensembl_gene_id"    => result["ensembl_gene_id"]
    }
  end
  
  # For each pipeline, keep all projects and their product availability
  result_data[ pipeline_name ][ result['ikmc_project_id'] ] = {
    'ikmc_project_id'   => result['ikmc_project_id'],
    'vector_available'  => result['vector_available'],
    'escell_available'  => result['escell_available'],
    'mouse_available'   => result['mouse_available']
  }
end

return sorted_results
