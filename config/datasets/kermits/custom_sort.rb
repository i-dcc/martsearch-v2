sorted_results = {}

@current_search_results.each do |result|
  
  # We're only interested in data with a status of 'Genotype Confirmed'
  if result["status"] and result["status"] === "Genotype Confirmed"
    
    # Correct the <> notation in several attributes...
    if result["allele_name"]
      result["allele_name"] = self.fix_superscript_text_in_attribute(result["allele_name"])
    end
    if result["back_cross_strain"]
      result["back_cross_strain"] = self.fix_superscript_text_in_attribute(result["back_cross_strain"])
    end
    
    # Store the result
    unless sorted_results[ result[ @joined_biomart_attribute ] ]
      sorted_results[ result[ @joined_biomart_attribute ] ] = []
    end
    sorted_results[ result[ @joined_biomart_attribute ] ].push(result)
    
  end
  
end

return sorted_results