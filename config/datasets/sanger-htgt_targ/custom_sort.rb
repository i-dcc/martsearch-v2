sorted_results = {}

@current_search_results.each do |result|
  
  # We're only interested in non KOMP-CSD/EUCOMM projects, AND 
  # projects that have generated ES Cells...
  process_result = false
  
  if !result["ikmc_project_id"].nil?
    if result["status_sequence"] and result["status_sequence"].to_i >= 95
      if result["is_komp_csd"] == "1" or result["is_eucomm"] == "1"
        process_result = true
      end
    end
  end
  
  if process_result
    # Create a results object if needed...
    if sorted_results[ result[ @joined_biomart_attribute ] ].nil?
      sorted_results[ result[ @joined_biomart_attribute ] ] = {}
    end
    
    # And a project entry...
    if sorted_results[ result[ @joined_biomart_attribute ] ][ result["ikmc_project_id"] ].nil?
      sorted_results[ result[ @joined_biomart_attribute ] ][ result["ikmc_project_id"] ] = {}
    end
    
    # Define our 'project' entry
    project = sorted_results[ result[ @joined_biomart_attribute ] ][ result["ikmc_project_id"] ]
    
    # Extract the singular (per project) values
    singular_attributes = [
      "is_eucomm", "is_komp_csd", "status", "status_type", "status_sequence",
      "pipeline_stage", "ikmc_project_id", "design_id",
      "design_plate", "design_well", "backbone", "cassette", 
      "allele_name", "is_latest_for_gene"
    ]
    
    singular_attributes.each do |attribute|
      project[attribute] = result[attribute]
    end
    
    # And Intermediate Vector info
    if result["intvec_distribute"] === "yes" or result["targvec_distribute"] === "yes"
      unless project["intermediate_vectors"]
        project["intermediate_vectors"] = []
      end
      
      int_vector = {
        "intvec_plate"      => result["intvec_plate"],
        "intvec_well"       => result["intvec_well"],
        "intvec_distribute" => result["intvec_distribute"]
      }
      
      unless project["intermediate_vectors"].include?(int_vector)
        project["intermediate_vectors"].push(int_vector)
      end
    end
    
    # And Targeting Vector info
    if result["targvec_distribute"] === "yes"
      unless project["targeting_vectors"]
        project["targeting_vectors"] = []
      end
      
      targ_vector = {
        "targvec_plate"      => result["targvec_plate"],
        "targvec_well"       => result["targvec_well"],
        "targvec_distribute" => result["targvec_distribute"]
      }
      
      unless project["targeting_vectors"].include?(targ_vector)
        project["targeting_vectors"].push(targ_vector)
      end
    end
    
    # And ES Cell info
    if result["escell_clone"] and ( result["escell_distribute"] or result["targeted_trap"] )
      clone = {
        "escell_clone"         => result["escell_clone"],
        "allele_name"          => result["allele_name"],
        "escell_line"          => result["escell_line"],
        "colonies_picked"      => result["colonies_picked"],
        "escell_distribute"    => result["escell_distribute"],
        "targeted_trap"        => result["targeted_trap"]
      }
      
      unless project["conditional_clones"]    then project["conditional_clones"]    = [] end
      unless project["nonconditional_clones"] then project["nonconditional_clones"] = [] end
      
      if result["targeted_trap"] or result["targvec_plate"] =~ /^D/
        project["nonconditional_clones"].push(clone)
      else
        project["conditional_clones"].push(clone)
      end
    end
  end
  
end

# Finally, sort the projects into a sensible order
sorted_results.each do |key,projects|
  sorted_projects = []
  
  projects.each do |project_id,project|
    if project["is_latest_for_gene"] == "1"
      sorted_projects.unshift(project)
    else
      sorted_projects.push(project)
    end
  end
  
  sorted_results[key] = sorted_projects
end

return sorted_results
