def status_sort( status )
  status_definitions = {
    "On Hold"                                            => { :sort => 1 },
    "Transferred to NorCOMM"                             => { :sort => 2 },
    "Transferred to KOMP"                                => { :sort => 3 },
    "Withdrawn From Pipeline"                            => { :sort => 4 },
    "Design Requested"                                   => { :sort => 5 },
    "Alternate Design Requested"                         => { :sort => 6 },
    "VEGA Annotation Requested"                          => { :sort => 7 },
    "Design Not Possible"                                => { :sort => 8 },
    "Design Completed"                                   => { :sort => 9 },
    "Vector Construction in Progress"                    => { :sort => 10 },
    "Vector Unsuccessful - Project Terminated"           => { :sort => 11 },
    "Vector Unsuccessful - Alternate Design in Progress" => { :sort => 12 },
    "Vector - Initial Attempt Unsuccessful"              => { :sort => 13 },
    "Vector Complete"                                    => { :sort => 14 }
  }
  return status_definitions[ status ]
end

#
# Sort projects on products availability (mice -> cells -> vectors -> nothing)
#
@@ms.search_data.each do |key, result_data|
  projects_with_mice    = []
  projects_with_clones  = []
  projects_with_vectors = []
  projects_with_nothing = [] # ie. No available product
  
  
  ##
  ##    1- Sorting on mice, cells and vectors availability
  ##    (mouse availability is retrieved from 'ikmc-dcc-knockout_attempts')
  ##
  if result_data['ikmc-idcc_targ_rep']
    result_data['ikmc-idcc_targ_rep'].each do |pipeline, pipeline_projects|
      displayed_project = nil
      
      pipeline_projects.each do |key, project|
      
        # Get mice availability
        if result_data['ikmc-dcc-knockout_attempts']
          ikmc_projects   = result_data['ikmc-dcc-knockout_attempts'][pipeline]
          ikmc_project_id = project['ikmc_project_id']
          
          if ikmc_projects and ikmc_projects[ikmc_project_id]
            project['mouse_available'] = ikmc_projects[ikmc_project_id]['mouse_available']
            project['ensembl_gene_id'] = ikmc_projects['ensembl_gene_id']
          end
        end
      
        # Push the most advanced project of this pipeline
        # to the right Array depending on its product availability
        displayed_project = key if displayed_project.nil?
        if project['mouse_available'] == '1'
          projects_with_mice.push( project )
          displayed_project = key unless pipeline_projects[displayed_project]['mouse_available'] == '1'
        
        elsif project['escell_available'] == '1' # From idcc-targ_rep custom sort
          projects_with_clones.push( project )
          displayed_project = key unless pipeline_projects[displayed_project]['mouse_available'] == '1'
        
        elsif project['vector_available'] == '1' # From idcc-targ_rep custom sort
          projects_with_vectors.push( project )
        end
      end
      
      pipeline_projects[displayed_project]['display'] = true
    end
  end
  
  ##
  ##   2- Append projects that don't have any distributable products
  ##    (from 'ikmc-dcc-knockout_attempts')
  ##
  next if result_data['ikmc-dcc-knockout_attempts'].nil?
  
  result_data['ikmc-dcc-knockout_attempts'].each do |pipeline, pipeline_details|
    next if pipeline == 'TIGM' # Skip if TIGM pipeline (ie. Targeted Trap)
    
    # Skip this pipeline if it's already reported in the targeting repository
    # (ie. has distributable products)
    next if result_data['ikmc-idcc_targ_rep'] and result_data['ikmc-idcc_targ_rep'].include? pipeline
    
    
    # Retrieve projects of this pipeline that don't have any product available
    projects = pipeline_details.values.select do |pipeline_detail|
      pipeline_detail.is_a? Hash                     \
      and pipeline_detail.has_key? 'ikmc_project_id' \
      and pipeline_detail['vector_available'] == '0' \
      and pipeline_detail['escell_available'] == '0' \
      and pipeline_detail['mouse_available']  == '0'
    end
    next if projects.empty?
    
    projects_with_nothing.push({
      'no_products_available' => true,
      'display'               => true,
      'pipeline'              => pipeline,
      'status'                => pipeline_details['status'],
      'mgi_accesion_id'       => pipeline_details['mgi_accession_id'],
      'project_ids'           => projects.collect { |p| p.values_at( 'ikmc_project_id' ) }.flatten
    })
  end
  
  result_data['ikmc-idcc_targ_rep'] = (
      projects_with_mice    \
    + projects_with_clones  \
    + projects_with_vectors \
    + projects_with_nothing
  )
end
