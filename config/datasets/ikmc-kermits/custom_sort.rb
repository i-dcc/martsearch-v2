sorted_results = {}

@current_search_results.each do |result|
  
  # We're only interested in data with a status of 'Genotype Confirmed'
  if result["status"] and result["status"] === "Genotype Confirmed"
    
    # Correct the <> notation in several attributes...
    if result["allele_name"]
      result["allele_name"] = self.fix_superscript_text_in_attribute(result["allele_name"])
      result["allele_type"] = case result["allele_name"]
      when /tm\d+a/ then "Conditional Knockout-First"
      when /tm\d+e/ then "Targeted Trap"
      when /tm\d\(/ then "Deletion"
      else               ""
      end
    end
    if result["back_cross_strain"]
      result["back_cross_strain"] = self.fix_superscript_text_in_attribute(result["back_cross_strain"])
    end
    
    # Test for QC data
    result['qc_count'] = 0
    qc_metrics = [
      "qc_southern_blot",
      "qc_tv_backbone_assay",
      "qc_five_prime_lr_pcr",
      "qc_loa_qpcr",
      "qc_homozygous_loa_sr_pcr",
      "qc_neo_count_qpcr",
      "qc_lacz_sr_pcr",
      "qc_five_prime_cass_integrity",
      "qc_neo_sr_pcr",
      "qc_mutant_specific_sr_pcr",
      "qc_loxp_confirmation",
      "qc_three_prime_lr_pcr"
    ]
    
    qc_metrics.each do |metric|
      if result[metric].nil?
        result[metric] = '-'
      else
        result['qc_count'] = result['qc_count'] + 1
      end
    end
    
    # Store the result
    unless sorted_results[ result[ @joined_biomart_attribute ] ]
      sorted_results[ result[ @joined_biomart_attribute ] ] = []
    end
    sorted_results[ result[ @joined_biomart_attribute ] ].push(result)
    
  end
  
end

return sorted_results