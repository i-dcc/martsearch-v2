sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {
      "marker_names"     => [],
      "synonyms"         => [],
      "ensembl_gene_ids" => [],
      "vega_gene_ids"    => [],
      "entrez_gene_ids"  => [],
      "go_entries"       => [],
      "human_orthologs"  => [],
      "rat_orthologs"    => []
    }
  end

  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]

  result_data["marker_symbol"]    = result["marker_symbol_107"]
  result_data["marker_type"]      = result["marker_type_107"]
  result_data["mgi_accession_id"] = result["mgi_marker_id_att"]
  result_data["chromosome"]       = result["chromosome_107"]
  result_data["start"]            = result["rep_genome_start_102"]
  result_data["end"]              = result["rep_genome_end_102"]
  result_data["strand"]           = result["rep_genome_strand_102"]

  result_data["marker_names"].push( result["marker_name_107"] )
  result_data["synonyms"].push( result["synonym_1010"] )
  result_data["ensembl_gene_ids"].push( result["ensembl_gene_id_103"] )
  result_data["vega_gene_ids"].push( result["vega_gene_id_1011"] )
  result_data["entrez_gene_ids"].push( result["mouse_entrez_gene_id_108"] )
  
  unless result["go_id_104_att"].nil? && result["go_term_104"].nil?
    result_data["go_entries"].push( { :id => result["go_id_104_att"], :term => result["go_term_104"] } )
  end
  
  unless result["human_symbol_105"].nil?
    result_data["human_orthologs"].push( { :symbol => result["human_symbol_105"], :entrez_gene_id => result["human_entrez_gene_id_105"] } )
  end
  
  unless result["rat_symbol_109"].nil?
    result_data["rat_orthologs"].push( { :symbol => result["rat_symbol_109"], :entrez_gene_id => result["rat_entrez_gene_id_109"] } )
  end
end

# Finally, ensure that the data in the arrays is unique
sorted_results.each do |key,result_data|
  result_data.keys.each do |field|
    if result_data[field].is_a?(Array)
      result_data[field].uniq!
    end
  end
end

return sorted_results
