sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {
      :projects        => {},
      :ccds_ids        => [],
      :omim_ids        => [],
      :tigm_gene_traps => []
    }
  end

  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]

  # Gene level data first...
  result_data[:mgi_accession_id]   = result["mgi_accession_id"]
  result_data[:igtc]               = result["igtc"]
  result_data[:imsr]               = result["imsr"]
  result_data[:mgi_gene_traps]     = result["mgi_gene_traps"]
  result_data[:targeted_mutations] = result["targeted_mutations"]
  result_data[:other_mutations]    = result["other_mutations"]
  
  unless result["ccds_id"].nil?
    result_data[:ccds_ids].push( result["ccds_id"] )
  end
  
  unless result["omim_ids"].nil?
    result_data[:omim_ids].push( result["omim_id"] )
  end
  
  # Now project information...
  
  unless result["ikmc_project_id"].nil?
    if result["ikmc_project"] === "TIGM"
      result_data[:tigm_gene_traps].push( result["ikmc_project_id"] )
    else
      result_data[:projects][ result["ikmc_project_id"] ] = {
        :project          => result["ikmc_project"],
        :project_id       => result["ikmc_project_id"],
        :status           => result["status"],
        :vector_available => result["vector_available"],
        :vector_generated => result["vector_generated"],
        :escell_available => result["escell_available"],
        :escell_generated => result["escell_generated"],
        :mouse_available  => result["mouse_available"],
        :mouse_generated  => result["mouse_generated"]
      }
    end
  end
end

# Finally, ensure that the data in the arrays is unique 
# and that we only return stuff when we have project info...
sorted_results.each do |key,result_data|
  if result_data[:projects].empty? and result_data[:tigm_gene_traps].empty?
    sorted_results[key] = nil
  else
    # TODO: write a sort function so that the more advanced products go at the top - see Jeremy's 'details.php' page for ideas!
    
    result_data[:ccds_ids].uniq!
    result_data[:omim_ids].uniq!
    result_data[:tigm_gene_traps].uniq!
  end
end

return sorted_results
