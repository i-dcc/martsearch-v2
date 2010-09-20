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
      "min_right"    => -1
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
  
  # Remove un-needed data from the sorted_results hash
  sorted_results_to_return[key] = {
    "chr"          => data["chr"],
    "start_pos"    => data["max_left"],
    "end_pos"      => data["min_right"],
    "s7_count"     => data["s7_count"],
    "b6_count"     => data["b6_count"],
    "micer_count"  => data["micer_count"]
  }
end

return sorted_results_to_return
