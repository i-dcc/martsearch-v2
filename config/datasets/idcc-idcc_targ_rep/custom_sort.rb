sorted_results = {}

@current_search_results.each do |result|
  next if result['pipeline_name'].nil?
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  unless result_data[ result['pipeline_name'] ]
    result_data[ result['pipeline_name'] ] = {
      'molecular_structure_id'  => result['molecular_structure_id'],
      'pipeline_name'           => result['pipeline_name'],
      'mgi_accession_id'        => result['mgi_accession_id'],
      'design_id'               => result['design_id'],
      'ikmc_project_id'         => result['ikmc_project_id'],
      'targeting_vectors'       => [],
      'conditional_clones'      => [],
      'nonconditional_clones'   => [],
      'vector_available'        => false,
      'escell_available'        => false,
      'mouse_available'         => false
    }
  end
  project = result_data[ result['pipeline_name'] ]
  
  #
  #   Targeting Vector
  #
  project['vector_available'] = true
  
  targ_vec = {
    'ikmc_project_id'     => result['ikmc_project_id'],
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
  
  # This project has cells, it might be more interesting than 
  # the one set initially.
  project['ikmc_project_id'] = result['ikmc_project_id']
  
  es_cell = {
    'escell_clone'              => result['escell_clone'],
    'allele_symbol_superscript' => result['allele_symbol_superscript'],
    'parental_cell_line'        => result['parental_cell_line'],
  }
  
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