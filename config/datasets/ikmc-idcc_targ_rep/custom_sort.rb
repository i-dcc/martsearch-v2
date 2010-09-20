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
      'pipeline'                => result['pipeline'],
      'mgi_accession_id'        => result['mgi_accession_id'],
      'design_id'               => result['design_id'],
      'design_type'             => result['design_type'],
      'targeting_vectors'       => [],
      'conditional_clones'      => [],
      'nonconditional_clones'   => [],
      'vector_available'        => '0',
      'escell_available'        => '0',
      'mouse_available'         => '0',
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
      'allele_id'           => result['allele_id'],
      'cassette'            => result['cassette'],
      'backbone'            => result['backbone'],
      'targeting_vector'    => result['targeting_vector'],
      'intermediate_vector' => result['intermediate_vector']
    }

    unless project['targeting_vectors'].include? targ_vec
      project['vector_available'] = '1'
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
      'qc_count'                  => 0
    }
    
    # Sort and store the QC metrics for the clones
    qc_metrics = [
      'production_qc_five_prime_screen',
      'production_qc_loxp_screen',
      'production_qc_three_prime_screen',
      'production_qc_loss_of_allele',
      'production_qc_vector_integrity',
      'distribution_qc_karyotype_high',
      'distribution_qc_karyotype_low',
      'distribution_qc_copy_number',
      'distribution_qc_five_prime_sr_pcr',
      'distribution_qc_three_prime_sr_pcr',
      'user_qc_southern_blot',
      'user_qc_map_test',
      'user_qc_karyotype',
      'user_qc_tv_backbone_assay',
      'user_qc_five_prime_lr_pcr',
      'user_qc_loss_of_wt_allele',
      'user_qc_neo_count_qpcr',
      'user_qc_lacz_sr_pcr',
      'user_qc_five_prime_cassette_integrity',
      'user_qc_neo_sr_pcr',
      'user_qc_mutant_specific_sr_pcr',
      'user_qc_loxp_confirmation',
      'user_qc_three_prime_lr_pcr',
      'user_qc_comment'
    ]
    
    qc_metrics.each do |metric|
      if result[metric].nil?
        es_cell[metric] = '-'
      else
        es_cell[metric]     = result[metric]
        es_cell['qc_count'] = es_cell['qc_count'] + 1
      end
    end
    
    # Push cells into to the right basket ('conditional' or 'nonconditional')
    if ['targeted_non_conditional', 'deletion'].include? result['mutation_subtype']
      clone_type = "nonconditional_clones"
      project['nonconditional_allele_id'] = result['allele_id']
    else
      clone_type = "conditional_clones"
      project['conditional_allele_id'] = result['allele_id']
    end
    
    unless project[clone_type].include? es_cell
      project['escell_available'] = '1'
      project[clone_type].push( es_cell )
    end
  end
end

return sorted_results