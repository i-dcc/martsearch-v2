sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  unless result_data[ result["ass_assay_id_key"] ]
    result_data[ result["ass_assay_id_key"] ] = {}
  end
  
  result_data_for_assay = result_data[ result["ass_assay_id_key"] ]
  
  result_data_for_assay["assay_id"]          = result["ass_assay_id_key"]
  result_data_for_assay["assay_image_count"] = result["assay_image_count"]
  
  unless result_data_for_assay["annotations"]
    result_data_for_assay["annotations"] = []
  end
  
  unless result["emap_id"].nil? && result["emap_term"].nil?
    result_data_for_assay["annotations"].push({
      "emap_id"      => result["emap_id"], 
      "emap_term"    => result["emap_term"],
      "ann_stage"    => result["ann_stage"],
      "ann_pattern"  => result["ann_pattern"],
      "ann_strength" => result["ann_strength"],
      "ann_comments" => result["ann_comments"]
    })
  end
  
  result_data_for_assay["annotations"].uniq!
end

# Now sort the annotations into order of the ones with more 
# annotations at the top...
results_to_return = {}

sorted_results.each do |id,results|
  assays = []
  results.each do |assay_id,assay_data|
    assays.push(assay_data)
  end
  results_to_return[id] = assays.sort_by { |a| -1*(a["annotations"].size) }
end

return results_to_return
