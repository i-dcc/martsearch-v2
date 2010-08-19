unless Module.const_defined?(:EUROPHENOME_MP_CONF)
  require "#{File.expand_path(File.dirname(__FILE__))}/config/datasets/europhenome-europhenome/routes.rb"
end

sorted_results = {}

europhenome_significance_cutoff = 0.0001

@current_search_results.each do |result|
  next unless result["mgi_accession_id"] and result["europhenome_id"] and result["significance"]
  
  if sorted_results[ result[ @joined_biomart_attribute ] ].nil?
    sorted_results[ result[ @joined_biomart_attribute ] ] = {}
  end
  
  ##
  ## First, set up a holder for a test_id/zygosity group
  ##
  
  het_hom = case result['zygosity'].to_s
    when '1' then 'Hom'
    when '0' then 'Het'
  end
  
  result_data = sorted_results[ result[ @joined_biomart_attribute ] ][ "#{result['europhenome_id']}-#{het_hom}" ]
  if result_data.nil?
    result_data = {
      'europhenome_id' => result['europhenome_id'],
      'line_name'      => result['line_name'],
      'zygosity'       => het_hom,
      'allele_id'      => result['allele_id'],
      'allele_name'    => result['allele_name'],
      'emma_id'        => result['emma_id'],
      'escell_clone'   => result['escell_clone'],
      'stocklist_id'   => result['stocklist_id'],
      'mp_groups'      => {} 
    }
  end
  
  ##
  ## Now process and store the individual results data...
  ##
  
  parameter_eslim_id = result["parameter_eslim_id"]
  test_eslim_id      = nil
  
  unless parameter_eslim_id.nil?
    test_eslim_id = parameter_eslim_id[ 0, ( parameter_eslim_id.size - 4 ) ]
  end
  
  # First, determine which MP group (top-level term) it belongs to
  mp_group = nil
  EUROPHENOME_MP_CONF.each do |mp_conf|
    next unless mp_group.nil?
    
    if result['mp_term']
      # Can we test by MP term?
      mp_group = mp_conf['term'] if mp_conf['child_terms'].include?( result['mp_term'] )
    else
      # No MP term - try to match via ESLIM ID's
      if test_eslim_id != nil
        mp_group = mp_conf['term'] if mp_conf['test_eslim_ids'].include?( test_eslim_id )
      end
    end
  end
  
  unless mp_group.nil?
    if result_data['mp_groups'][mp_group].nil?
      result_data['mp_groups'][mp_group] = {
        'male_results'          => { 'significant' => [], 'insignificant' => [] },
        'female_results'        => { 'significant' => [], 'insignificant' => [] },
        'is_male_significant'   => nil,
        'is_female_significant' => nil,
      }
    end
    
    sex_basket       = "#{result['sex'].downcase}_results"
    sex_significance = "is_#{result['sex'].downcase}_significant"
    data_to_save = {
      'parameter_name'     => result['parameter_name'],
      'parameter_eslim_id' => parameter_eslim_id,
      'test_eslim_id'      => test_eslim_id,
      'significance'       => result['significance'],
      'effect_size'        => result['effect_size'],
      'mp_term'            => result['mp_term'],
      'mp_term_name'       => result['mp_term_name']
    }
    
    # Assess the significance of the result, then store the data...
    if BigDecimal.new(result['significance']).to_f < europhenome_significance_cutoff
      result_data['mp_groups'][mp_group][sex_basket]['significant'].push(data_to_save)
      result_data['mp_groups'][mp_group][sex_significance] = true
    else
      result_data['mp_groups'][mp_group][sex_basket]['insignificant'].push(data_to_save)
      if result_data['mp_groups'][mp_group][sex_significance].nil?
        result_data['mp_groups'][mp_group][sex_significance] = false
      end
    end
  end
  
  sorted_results[ result[ @joined_biomart_attribute ] ][ "#{result['europhenome_id']}-#{het_hom}" ] = result_data
end

return sorted_results