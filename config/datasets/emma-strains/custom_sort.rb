sorted_results = {}

@current_search_results.each do |result|
  next unless result["emma_id"]
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ][ result["emma_id"] ]
    sorted_results[ result[ @joined_biomart_attribute ] ][ result["emma_id"] ] = {
      "references"   => {},
      "availability" => []
    }
  end
  
  emma_record = sorted_results[ result[ @joined_biomart_attribute ] ][ result["emma_id"] ]
  
  # Add singular info first...
  singles = [
    "emma_id",
    "international_strain_name",
    "synonym",
    "maintained_background",
    "mutation_main_type",
    "mutation_sub_type",
    "genetic_description",
    "phenotype_description",
    "owner"
  ]
  
  singles.each do |attribute|
    emma_record[attribute] = result[attribute]
  end
  
  # Allele name...
  emma_record["allele_name"] = self.fix_superscript_text_in_attribute(result["alls_form"])
  
  # References...
  unless result["pubmed_id"].nil?
    emma_record["references"][result["pubmed_id"]] = {
      "pubmed_id" => result["pubmed_id"],
      "reference" => result["reference"]
    }
  end
  
  # Availability...
  unless result["availability"].nil?
    emma_record["availability"].push(result["availability"])
  end
end

return sorted_results