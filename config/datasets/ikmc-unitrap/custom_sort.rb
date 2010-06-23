sorted_results = {}

##
## Collate all of the info we need from the result data
##

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  
  data = sorted_results[ result[ @joined_biomart_attribute ] ]
  
  unitrap_id = result['unitrap_accession_id']
  project    = result['project']
  
  data[ unitrap_id ]            = {} unless data[ unitrap_id ]
  data[ unitrap_id ][ project ] = [] unless data[ unitrap_id ][ project ]
  
  data[ unitrap_id ][ project ].push(result)
end

return sorted_results
