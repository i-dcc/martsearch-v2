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
      'traps'                => {},
      'project_counts_total' => {},
      'unitrap_counts_total' => {}
    }
    
    data = sorted_results[ result[ @joined_biomart_attribute ] ]
    projects.each do |proj|
      data['project_counts_total'][proj] = 0
      data['traps'][proj]                = {}
    end
  end
  
  data       = sorted_results[ result[ @joined_biomart_attribute ] ]
  unitrap_id = result['unitrap_accession_id']
  project    = result['project']
  
  # Instanciate variables
  data['traps'][ project ][ unitrap_id ]     = [] unless data['traps'][ project ][ unitrap_id ]
  data['unitrap_counts_total'][ unitrap_id ] = 0  unless data['unitrap_counts_total'][ unitrap_id ]
  
  # Increment counts
  data['unitrap_counts_total'][ unitrap_id ] = data['unitrap_counts_total'][ unitrap_id ] + 1
  data['project_counts_total'][ project ]    = data['project_counts_total'][ project ] + 1
  
  # Store data
  data['traps'][ project ][ unitrap_id ].push(result)
end

##
## After the first pass, quickly collate the traps into a 
## useful (sorted and grouped) data structure for the template...
##

sorted_results.each do |result_key,result_value|
  result_value['traps_by'] = {}
  
  # Group traps by project...
  result_value['project_counts_total'].keys.each do |project|
    traps = result_value['traps'][project].values.flatten
    traps.sort!{ |a,b| a['unitrap_accession_id'] <=> b['unitrap_accession_id'] }
    
    result_value['traps_by'][project] = traps
  end
  
  # Group traps by unitrap...
  result_value['unitrap_counts_total'].keys.each do |unitrap|
    traps = []
    result_value['traps'].each do |project,data_by_unitrap|
      traps.push( data_by_unitrap[unitrap] ) unless data_by_unitrap[unitrap].nil?
    end
    traps = traps.flatten.sort{ |a,b| a['project'] <=> b['project'] }
    
    result_value['traps_by'][unitrap] = traps
  end
end

return sorted_results
