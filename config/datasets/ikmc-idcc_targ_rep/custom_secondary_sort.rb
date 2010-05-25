status_order = {
  "On Hold"                                            => 1,
  "Transferred to NorCOMM"                             => 2,
  "Transferred to KOMP"                                => 3,
  "Withdrawn From Pipeline"                            => 4,
  "Design Requested"                                   => 5,
  "Alternate Design Requested"                         => 6,
  "VEGA Annotation Requested"                          => 7,
  "Design Not Possible"                                => 8,
  "Design Completed"                                   => 9,
  "Vector Construction in Progress"                    => 10,
  "Vector Unsuccessful - Project Terminated"           => 11,
  "Vector Unsuccessful - Alternate Design in Progress" => 12,
  "Vector - Initial Attempt Unsuccessful"              => 13,
  "Vector Complete"                                    => 14
}

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
    
    # Skip this pipeline if it's already reported in the targeting repository (ie. has distributable products)
    next if result_data['ikmc-idcc_targ_rep'] and result_data['ikmc-idcc_targ_rep'].include? pipeline
    
    # Retrieve projects_ids of this pipeline that don't have any product available
    projects_ids      = []
    projects_statuses = []
    
    pipeline_details.values.each do |project|
      if project.is_a? Hash and project.values_at('vector_available','escell_available','mouse_available') == ['0','0','0']
        projects_ids.push( project['ikmc_project_id'] )
        projects_statuses.push( project['status'] )
      end
    end
    next if projects_ids.empty? or projects_statuses.empty?
    
    projects_with_nothing.push({
      'no_products_available' => true,
      'display'               => true,
      'pipeline'              => pipeline,
      'status'                => projects_statuses.sort { |a,b| status_order[a] <=> status_order[b] }.first,
      'mgi_accesion_id'       => pipeline_details['mgi_accession_id'],
      'project_ids'           => projects_ids
    })
  end
  
  result_data['ikmc-idcc_targ_rep'] = (
      projects_with_mice    \
    + projects_with_clones  \
    + projects_with_vectors \
    + projects_with_nothing
  )
end
