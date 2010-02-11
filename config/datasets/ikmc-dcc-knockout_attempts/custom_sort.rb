sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {
      "projects"        => {}
    }
  end

  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]

  # Gene level data first...
  result_data["mgi_accession_id"]   = result["mgi_accession_id"]
  result_data["igtc"]               = result["igtc"]
  result_data["imsr"]               = result["imsr"]
  result_data["mgi_gene_traps"]     = result["mgi_gene_traps"]
  result_data["targeted_mutations"] = result["targeted_mutations"]
  result_data["other_mutations"]    = result["other_mutations"]
  
  # Now project information...
  
  unless result["ikmc_project_id"].nil?
    if result["ikmc_project"] === "TIGM"
      unless result_data["projects"]["TIGM"]
        result_data["projects"]["TIGM"] = []
      end
      result_data["projects"]["TIGM"].push( result["ikmc_project_id"] )
    else
      result_data["projects"][ result["ikmc_project_id"] ] = {
        "project"          => result["ikmc_project"],
        "project_id"       => result["ikmc_project_id"],
        "status"           => result["status"],
        "vector_available" => result["vector_available"],
        "vector_generated" => result["vector_generated"],
        "escell_available" => result["escell_available"],
        "escell_generated" => result["escell_generated"],
        "mouse_available"  => result["mouse_available"],
        "mouse_generated"  => result["mouse_generated"]
      }
    end
  end
end

# Finally, ensure that the data in the arrays is unique 
# and that we only return stuff when we have project info...
entries_to_delete = []
sorted_results.each do |key,result_data|
  if result_data["projects"].empty?
    entries_to_delete.push(key)
  else
    # TODO: write a sort function so that the more advanced products go at the top - see Jeremy's 'details.php' page for ideas!
  end
end

entries_to_delete.each do |key|
  sorted_results.delete(key)
end

return sorted_results
