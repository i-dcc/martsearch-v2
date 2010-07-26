sorted_results = {}

@current_search_results.each do |result|
  next if result['disorder_name'].nil?
  
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = []
  end
  
  sorted_results[ result[ @joined_biomart_attribute ] ].push(result)
end

sorted_results.each do |key,omim_values|
  sorted_results[key] = omim_values.sort{ |a,b| a['disorder_name'] <=> b['disorder_name'] }
end

return sorted_results
