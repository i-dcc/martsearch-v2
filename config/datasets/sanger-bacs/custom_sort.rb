sorted_results = {}

##
## Collate all of the info we need from the result data
##

@current_search_results.each do |result|
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {
      "chr"          => result["chromosome"],
      "s7_count"     => 0,
      "b6_count"     => 0,
      "micer_count"  => 0,
      "min_left"     => -1,
      "max_right"    => -1,
      "max_left"     => -1,
      "min_right"    => -1,
      "ensembl_link" => nil
    }
  end
  
  data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  if    result['library'] === '129S7'    then data["s7_count"]    += 1
  elsif result['library'] === 'C57Bl/6J' then data["b6_count"]    += 1
  elsif result['library'] === 'MICER'    then data["micer_count"] += 1
  end
  
  start_pos = Integer(result["start"])
  end_pos   = Integer(result["end"])
  
  if (data["min_left"] < 0) or (data["min_left"] > start_pos) then data["min_left"]  = start_pos end
  if (data["max_right"] < end_pos)                            then data["max_right"] = end_pos   end
  if (data["max_left"] < 0) or (data["max_left"] < start_pos) then data["max_left"]  = start_pos end
  if (data["min_right"] < 0) or (end_pos < data["min_right"]) then data["min_right"] = end_pos   end
  
end

##
## Now do some post-processing on this data, to 
## configure our link out to Ensembl...
##

sorted_results_to_return = {}

sorted_results.each do |key,data|
  
  if data["min_right"] < data["max_left"]
    tmp = data["min_right"]
    data["min_right"] = data["max_left"]
    data["max_left"] = tmp
  end
  
  data["max_left"]  = data["max_left"]  - 10000
  data["min_right"] = data["min_right"] + 10000
  
  tracks_to_change = {
    "contig"                                          => "normal",
    "ruler"                                           => "normal",
    "scalebar"                                        => "normal",
    "transcript_core_ensembl"                         => "compact",
    "transcript_vega_otter"                           => "off",
    "alignment_compara_364_constrained"               => "off",
    "das:http://das.sanger.ac.uk/das/ens_m37_129AB22" => "normal",
    "das:http://das.sanger.ac.uk/das/ens_m37_micer"   => "normal",
    "das:http://das.sanger.ac.uk/das/ens_m37_bacmap"  => "normal",
    "alignment_compara_364_scores"                    => "off",
    "chr_band_core"                                   => "off",
    "dna_align_cdna_cDNA_update"                      => "off",
    "dna_align_core_CCDS"                             => "off",
    "fg_regulatory_features_funcgen"                  => "off",
    "fg_regulatory_features_legend"                   => "off",
    "gene_legend"                                     => "off",
    "gc_plot"                                         => "off",
    "info"                                            => "off",
    "missing"                                         => "off",
    "transcript_core_ncRNA"                           => "off",
    "transcript_core_ensembl_IG_gene"                 => "off",
    "variation_legend"                                => "off"
  }

  settings = [];
  tracks_to_change.each do |track,setting|
    settings.push("#{track}=#{setting}")
  end

  ensembl_link = "http://www.ensembl.org/Mus_musculus/Location/View"
  ensembl_link += "?r=#{data["chr"]}:#{data["max_left"]}-#{data["min_right"]};"
  ensembl_link += "contigviewbottom=#{settings.join(",")}"
  
  # Remove un-needed data from the sorted_results hash
  sorted_results_to_return[key] = {
    "s7_count"     => data["s7_count"],
    "b6_count"     => data["b6_count"],
    "micer_count"  => data["micer_count"],
    "ensembl_link" => ensembl_link
  }
end

return sorted_results_to_return
