
@@ms.search_data.each do |key,result_data|
  next if result_data['ikmc-idcc_targ_rep'].nil?
  
  # For now, mouse availability is unknown by targ_rep dataset.
  # Sorting will be made here until targ_rep dataset can read KO attempts dataset
  projects_with_mice    = []
  projects_with_clones  = []
  projects_with_vectors = []
  
  result_data['ikmc-idcc_targ_rep'].each do |pipeline, pipeline_projects|
    displayed_project = nil
    
    pipeline_projects.each do |key, project|
      # Get mouse availability from 'ikmc-dcc-knockout_attempts' dataset
      if result_data['ikmc-dcc-knockout_attempts']
        ikmc_projects    = result_data['ikmc-dcc-knockout_attempts'][pipeline]
        ikmc_project_id = project['ikmc_project_id']
        
        if ikmc_project and ikmc_projects[ikmc_project_id]
          project['mouse_available'] = ikmc_projects[ikmc_project_id]['mouse_available']
          project['ensembl_gene_id'] = ikmc_projects['ensembl_gene_id']
        end
      end
      
      displayed_project = key if displayed_project.nil?
      
      # Push project to the right Array depending on product availability - for sorting.
      if project['mouse_available']
        projects_with_mice.push( project )
        displayed_project = key unless pipeline_projects[displayed_project]['mouse_available']
        
      elsif project['escell_available']
        projects_with_clones.push( project )
        displayed_project = key unless pipeline_projects[displayed_project]['mouse_available']
        
      elsif project['vector_available']
        projects_with_vectors.push( project )
      end
    end
    
    pipeline_projects[displayed_project]['display'] = true
  end
  
  result_data['ikmc-idcc_targ_rep'] = (projects_with_mice + projects_with_clones + projects_with_vectors).freeze
  
end
