sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
    
    result.keys.each do |key|
      sorted_results[ result[ @joined_biomart_attribute ] ][key] = []
    end
  end
  
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  result.keys.each do |key|
    result_data[key].push( result[key] )
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
