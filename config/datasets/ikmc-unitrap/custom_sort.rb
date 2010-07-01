##
## First cache all the possible projects from the UniTrap mart
##

# unless @@ms.cache.fetch('ikmc-unitrap-projects')
#   projects = []
#   results = @@ms.datasets_by_name[:"ikmc-unitrap"].dataset.search(
#     :attributes          => ['project'],
#     :required_attributes => ['project']
#   )
#   
#   results[:data].each do |data_line|
#     projects.push( data_line[0] )
#   end
#   
#   @@ms.cache.write( 'ikmc-unitrap-projects', projects.to_json, :expires_in => 24.hours )
# end
# 
# projects = JSON.parse( @@ms.cache.fetch('ikmc-unitrap-projects') )

projects = @@ms.datasets_by_name[:"ikmc-unitrap"].config['searching']['filters']['pipeline']

##
## Collate all of the info we need from the result data
##

sorted_results = {}

@current_search_results.each do |result|
  unless sorted_results[ result[ @joined_biomart_attribute ] ]
    sorted_results[ result[ @joined_biomart_attribute ] ] = {
      'data'           => {},
      'project_counts' => {},
      'unitrap_counts' => {}
    }
    
    data = sorted_results[ result[ @joined_biomart_attribute ] ]
    projects.each do |proj|
      data['project_counts'][proj] = 0
      data['data'][proj]           = {}
    end
  end
  
  data       = sorted_results[ result[ @joined_biomart_attribute ] ]
  unitrap_id = result['unitrap_accession_id']
  project    = result['project']
  
  # Instanciate variables
  data['data'][ project ][ unitrap_id ] = [] unless data['data'][ project ][ unitrap_id ]
  data['unitrap_counts'][ unitrap_id ]  = 0  unless data['unitrap_counts'][ unitrap_id ]
  
  # Increment counts
  data['unitrap_counts'][ unitrap_id ] = data['unitrap_counts'][ unitrap_id ] + 1
  data['project_counts'][ project ]    = data['project_counts'][ project ] + 1
  
  # Store data
  data['data'][ project ][ unitrap_id ].push(result)
end

return sorted_results
