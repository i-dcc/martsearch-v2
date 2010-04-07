sorted_results = {}

@current_search_results.each do |result|
  next if result['pipeline_name'].nil?
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  unless result_data[ result['pipeline_name'] ]
    result_data[ result['pipeline_name'] ] = {}
  end
  
  pipeline = result_data[ result['pipeline_name'] ]
  key = [
    result['homology_arm_start'],
    result['homology_arm_end'],
    result['cassette_start'],
    result['cassette_end'],
    result['cassette'],
    result['backbone']
  ]
  unless pipeline[ key ]
    pipeline[ key ] = {
      'molecular_structure_id'  => result['molecular_structure_id'],
      'pipeline_name'           => result['pipeline_name'],
      'mgi_accession_id'        => result['mgi_accession_id'],
      'design_id'               => result['design_id'],
      'targeting_vectors'       => [],
      'conditional_clones'      => [],
      'nonconditional_clones'   => [],
      'vector_available'        => false,
      'escell_available'        => false,
      'mouse_available'         => false,
      'display'                 => false
    }
  end
  
  project = pipeline[ key ]
  
  # Get ikmc_project_id
  unless result['ikmc_project_id'].nil? or result['ikmc_project_id'].empty?
    project['ikmc_project_id'] = result['ikmc_project_id']
    ikmc_project_id = result['ikmc_project_id']
  else
    ikmc_project_id = project['ikmc_project_id']
  end
  
  #
  #   Targeting Vector
  #
  project['vector_available'] = true
  
  targ_vec = {
    'ikmc_project_id'     => ikmc_project_id,
    'cassette'            => result['cassette'],
    'backbone'            => result['backbone'],
    'targeting_vector'    => result['targeting_vector'],
    'intermediate_vector' => result['intermediate_vector']
  }
  unless project['targeting_vectors'].include? targ_vec
    project['targeting_vectors'].push( targ_vec )
  end
  
  
  #
  #   ES Cell
  #
  next unless result['escell_clone']
  project['escell_available'] = true
  
  es_cell = {
    'ikmc_project_id'           => ikmc_project_id,
    'targeting_vector'          => result['targeting_vector'],
    'escell_clone'              => result['escell_clone'],
    'allele_symbol_superscript' => result['allele_symbol_superscript'],
    'parental_cell_line'        => result['parental_cell_line'],
  }
  
  # Push ES Cell clone to the right Array (``conditional`` or ``nonconditional``)
  if result['design_type'] == 'Knock Out' and result['loxp_start'].nil?
    clone_type = "nonconditional_clones"
  else
    clone_type = "conditional_clones"
  end
  
  unless project[clone_type].include? es_cell
    project[clone_type].push( es_cell )
  end
end

return sorted_results