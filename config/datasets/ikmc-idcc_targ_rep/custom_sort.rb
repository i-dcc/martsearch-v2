sorted_results = {}

@current_search_results.each do |result|
  next if result['pipeline'].nil?
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  unless result_data[ result['pipeline'] ]
    result_data[ result['pipeline'] ] = {}
  end
  
  pipeline_store = result_data[ result['pipeline'] ]
  project_key = [
    result['homology_arm_start'],
    result['homology_arm_end'],
    result['cassette_start'],
    result['cassette_end'],
    result['cassette'],
    result['backbone']
  ]
  
  unless pipeline_store[ project_key ]
    pipeline_store[ project_key ] = {
      'allele_id'               => result['allele_id'],
      'pipeline'                => result['pipeline'],
      'mgi_accession_id'        => result['mgi_accession_id'],
      'design_id'               => result['design_id'],
      'design_type'             => result['design_type'],
      'targeting_vectors'       => [],
      'conditional_clones'      => [],
      'nonconditional_clones'   => [],
      'vector_available'        => false,
      'escell_available'        => false,
      'mouse_available'         => false,
      'display'                 => false
    }
  end
  
  project = pipeline_store[ project_key ]
  
  # Get the ikmc_project_id
  unless result['ikmc_project_id'].nil? or result['ikmc_project_id'].empty?
    project['ikmc_project_id'] = result['ikmc_project_id']
    ikmc_project_id = result['ikmc_project_id']
  else
    ikmc_project_id = project['ikmc_project_id']
  end
  
  # Targeting Vectors
  if result['targeting_vector']
    targ_vec = {
      'ikmc_project_id'     => ikmc_project_id,
      'cassette'            => result['cassette'],
      'backbone'            => result['backbone'],
      'targeting_vector'    => result['targeting_vector'],
      'intermediate_vector' => result['intermediate_vector']
    }

    unless project['targeting_vectors'].include? targ_vec
      project['vector_available'] = true
      project['targeting_vectors'].push( targ_vec )
    end
  end
  
  # ES Cells
  if result['escell_clone']
    es_cell = {
      'ikmc_project_id'           => ikmc_project_id,
      'targeting_vector'          => result['targeting_vector'],
      'escell_clone'              => result['escell_clone'],
      'allele_symbol_superscript' => result['allele_symbol_superscript'],
      'parental_cell_line'        => result['parental_cell_line'],
    }
  
    # Push cells into to the right basket ('conditional' or 'nonconditional')
    if result['loxp_start'].nil?
      clone_type = "nonconditional_clones"
    else
      clone_type = "conditional_clones"
    end
    
    unless project[clone_type].include? es_cell
      project['escell_available'] = true
      project[clone_type].push( es_cell )
    end
  end
end

return sorted_results