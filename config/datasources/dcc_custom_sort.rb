sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {
      "marker_names"     => [],
      "synonyms"         => [],
      "ensembl_gene_ids" => [],
      "vega_gene_ids"    => [],
      "entrez_gene_ids"  => [],
      "ccds_ids"         => [],
      "omim_ids"         => []
    }
  end

  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]

  result_data["marker_symbol"]    = result["marker_symbol"];
  result_data["mgi_accession_id"] = result["mgi_accession_id"];
  result_data["chromosome"]       = result["chromosome"];
  result_data["start"]            = result["start"];
  result_data["end"]              = result["end"];

  result_data["marker_names"].push( result["marker_name"] );
  result_data["synonyms"].push( result["synonym"] );
  result_data["ensembl_gene_ids"].push( result["ensembl_gene_id"] );
  result_data["vega_gene_ids"].push( result["vega_gene_id"] );
  result_data["entrez_gene_ids"].push( result["entrez_gene_id"] );
  result_data["ccds_ids"].push( result["ccds_id"] );
  result_data["omim_ids"].push( result["omim_id"] );
end

# Finally, ensure that the data in the arrays is unique
sorted_results.each do |key,result_data|
  result_data["marker_names"].uniq!
  result_data["synonyms"].uniq!
  result_data["ensembl_gene_ids"].uniq!
  result_data["vega_gene_ids"].uniq!
  result_data["entrez_gene_ids"].uniq!
  result_data["ccds_ids"].uniq!
  result_data["omim_ids"].uniq!
end

return sorted_results
