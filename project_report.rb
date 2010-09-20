["/project/:id","/project/?"].each do |path|
  get path do
    project_id  = params[:id]
    
    @current    = "home"
    @page_title = "Report for project #{project_id}"
    
    cached_data = @@ms.cache.fetch("project-report-#{project_id}")
    if cached_data.nil? or params[:fresh] == "true"
      @data       = { 'project_id' => project_id }
      common_data = get_common_data(project_id)
      
      if common_data.nil?
        @data = nil
      else
        @data.update( common_data )
        @data.update( get_mice(@data['marker_symbol']) ) if @data['marker_symbol']
        @data.update( get_vectors_and_cells( project_id, @data['mice'] ) )
        @data.update( order_buttons_url(@data) )
        @data.update( get_pipeline_stage( @data['status']) ) if @data['status']

        @@ms.cache.write("project-report-#{project_id}", Marshal.dump(@data), :expires_in => 3.hours )
      end
    else
      @data = Marshal.load(cached_data)
    end
    
    if @data.nil?
      status 404
      erubis :not_found
    else
      if params[:wt] == "json"
        content_type "application/json"
        return @data.to_json
      else
        erubis :project_report
      end
    end
  end
end

# Will query DCC gene details mart
def get_common_data( project_id )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/ikmc-dcc-gene_details/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters    => { 'ikmc_project_id' => project_id },
    :attributes => [ 'marker_symbol', 'mgi_accession_id', 'ensembl_gene_id', 
      'vega_gene_id', 'ikmc_project', 'status', 
      'mouse_available', 'escell_available', 'vector_available' ],
    :process_results => true
  })
  
  return results[0]
end

# Will query IDCC targ rep mart
def get_vectors_and_cells( project_id, mouse_data )
  conf       = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/ikmc-idcc_targ_rep/config.json","r") )
  dataset    = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  qc_metrics = [
      'production_qc_five_prime_screen',
      'production_qc_loxp_screen',
      'production_qc_three_prime_screen',
      'production_qc_loss_of_allele',
      'production_qc_vector_integrity',
      'distribution_qc_karyotype_high',
      'distribution_qc_karyotype_low',
      'distribution_qc_copy_number',
      'distribution_qc_five_prime_sr_pcr',
      'distribution_qc_three_prime_sr_pcr',
      'user_qc_southern_blot',
      'user_qc_map_test',
      'user_qc_karyotype',
      'user_qc_tv_backbone_assay',
      'user_qc_five_prime_lr_pcr',
      'user_qc_loss_of_wt_allele',
      'user_qc_neo_count_qpcr',
      'user_qc_lacz_sr_pcr',
      'user_qc_five_prime_cassette_integrity',
      'user_qc_neo_sr_pcr',
      'user_qc_mutant_specific_sr_pcr',
      'user_qc_loxp_confirmation',
      'user_qc_three_prime_lr_pcr'
  ]
  results = dataset.search({
    :filters => { 'ikmc_project_id' => project_id },
    :attributes => [
      'allele_id',
      'design_id',
      'mutation_subtype',
      'cassette',
      'backbone',
      'intermediate_vector',
      'targeting_vector',
      'allele_symbol_superscript',
      'escell_clone',
      'floxed_start_exon',
      'parental_cell_line',
      qc_metrics
     ].flatten,
    :process_results => true
  })

  data = {}

  results.each do |result|
    if data.empty?
      data.update(
        'intermediate_vectors' => [],
        'targeting_vectors'    => [],
        'es_cells'             => {
          'conditional'              => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }, 
          'targeted non-conditional' => { 'cells' => [], 'allele_img' => nil, 'allele_gb' => nil }
        },
        'vector_image' => "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/vector-image",
        'vector_gb'    => "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
      )
    end
    
    design_type = case result['mutation_subtype']
      when 'conditional_ready'        then 'Conditional (Frameshift)'
      when 'deletion'                 then 'Deletion'
      when 'targeted_non_conditional' then 'Targeted, Non-Conditional'
      else ''
    end
    
    ##
    ## Intermediate Vectors
    ##
    
    data['intermediate_vectors'].push(
      'name'        => result['intermediate_vector'],
      'design_id'   => result['design_id'],
      'design_type' => design_type,
      'floxed_exon' => result['floxed_start_exon']
    ) unless result['mutation_subtype'] == 'targeted_non_conditional'
    
    ##
    ## Targeting Vectors
    ##
    
    data['targeting_vectors'].push(
      'name'         => result['targeting_vector'],
      'design_id'    => result['design_id'],
      'design_type'  => design_type,
      'cassette'     => result['cassette'],
      'backbone'     => result['backbone'],
      'floxed_exon'  => result['floxed_start_exon']
    ) unless result['mutation_subtype'] == 'targeted_non_conditional'
    
    ##
    ## ES Cells
    ##
    
    next if result['escell_clone'].nil? or result['escell_clone'].empty?

    push_to = 'targeted non-conditional'
    push_to = 'conditional' if result['mutation_subtype'] == 'conditional_ready'

    # Prepare the QC data
    qc_data = { 'qc_count' => 0 }
    qc_metrics.each do |metric|
      if result[metric].nil?
        qc_data[metric]     = '-'
      else
        qc_data[metric]     = result[metric]
        qc_data['qc_count'] = qc_data['qc_count'] + 1
      end
    end

    data['es_cells'][push_to]['allele_img'] = "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/allele-image"
    data['es_cells'][push_to]['allele_gb']  = "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/escell-clone-genbank-file"
    data['es_cells'][push_to]['cells'].push({
      'name'                      => result['escell_clone'],
      'allele_symbol_superscript' => result['allele_symbol_superscript'],
      'parental_cell_line'        => result['parental_cell_line'],
      'targeting_vector'          => result['targeting_vector'],
      'mouse?'                    => mouse_data.any?{ |mouse| mouse['escell_clone'] == result['escell_clone'] } ? 'yes' : 'no'
    }.merge(qc_data) )
  end
  
  unless data.empty?
    data['intermediate_vectors'].uniq!
    data['targeting_vectors'].uniq!
    
    # Uniqify and sort the ES Cells...
    ['conditional','targeted non-conditional'].each do |cond_vs_non|
      data['es_cells'][cond_vs_non]['cells'].uniq!
      data['es_cells'][cond_vs_non]['cells'].sort! do |elm1,elm2|
        compstr1 = ''
        compstr2 = ''
        
        if elm1['mouse?'] == 'yes' then compstr1 = 'A '
        else                            compstr1 = 'Z '
        end
        
        if elm2['mouse?'] == 'yes' then compstr2 = 'A '
        else                            compstr2 = 'Z '
        end
        
        compstr1 << "#{elm1['qc_count']} "
        compstr1 << elm1['name']
        
        compstr2 << "#{elm2['qc_count']} "
        compstr2 << elm2['name']
        
        compstr1 <=> compstr2
      end
    end
  end
  
  return data
end

# Will query Kermits mart
def get_mice( marker_symbol )
  conf       = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/ikmc-kermits/config.json","r") )
  dataset    = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  qc_metrics = [
        'qc_southern_blot',
        'qc_tv_backbone_assay',
        'qc_five_prime_lr_pcr',
        'qc_loa_qpcr',
        'qc_homozygous_loa_sr_pcr',
        'qc_neo_count_qpcr',
        'qc_lacz_sr_pcr',
        'qc_five_prime_cass_integrity',
        'qc_neo_sr_pcr',
        'qc_mutant_specific_sr_pcr',
        'qc_loxp_confirmation',
        'qc_three_prime_lr_pcr'
  ]
  results = dataset.search({
    :filters => { 'marker_symbol' => marker_symbol, 'active' => '1' },
    :attributes => [
        'status',
        'allele_name',
        'escell_clone',
        'escell_strain',
        'escell_line',
        'mi_centre',
        qc_metrics
    ].flatten,
    :required_attributes => ['status'],
    :process_results     => true
  })

  # Test for QC data - set each empty qc_metric to '-' or count it
  results.each do |result|
    result['qc_count'] = 0
    qc_metrics.each do |metric|
      if result[metric].nil?
        result[metric] = '-'
      else
        result['qc_count'] = result['qc_count'] + 1
      end
    end
  end

  results.empty? ? {} : { 'mice' => results }
end

def order_buttons_url( data )
  mgi_accession_id  = data['mgi_accession_id'][4..-1]
  pipeline          = data['ikmc_project']
  marker_symbol     = data['marker_symbol']
  project_id        = data['project_id']
  
  if pipeline == "KOMP-CSD"
    return {
      'order_vector_url'   => "http://www.komp.org/vectorOrder.php?projectid=#{project_id}",
      'order_cell_url'     => "http://www.komp.org/orders.php?project=CSD#{project_id}&amp;product=1",
      'order_default_url'  => "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
    }
  elsif pipeline == "KOMP-Regeneron"
    return {
      'order_vector_url'   => "http://www.komp.org/vectorOrder.php?projectid=#{project_id}",
      'order_cell_url'     => "http://www.komp.org/orders.php?project=#{project_id}&amp;product=1",
      'order_default_url'  => "http://www.komp.org/geneinfo.php?project=#{project_id}"
    }
  elsif pipeline == "EUCOMM" or pipeline == "mirKO"
    return {
      'order_vector_url'   => "http://www.eummcr.org/final_vectors.php?mgi_id=#{mgi_accession_id}",
      'order_cell_url'     => "http://www.eummcr.org/es_cells.php?mgi_id=#{mgi_accession_id}",
      'order_mouse_url'    => "http://www.emmanet.org/mutant_types.php?keyword=#{marker_symbol}%25EUCOMM&select_by=InternationalStrainName&search=ok",
      'order_default_url'  => "http://www.eummcr.org/order.php"
    }
  elsif pipeline == "NorCOMM"
    return {
      'order_default_url'  => "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
    }
  else
    return {}
  end
end

def get_pipeline_stage( status )
  status_definitions = {
    "On Hold"                                                 => { :stage => "pre",     :stage_type => "warn"   },
    "Transferred to NorCOMM"                                  => { :stage => "pre",     :stage_type => "error"  },
    "Transferred to KOMP"                                     => { :stage => "pre",     :stage_type => "error"  },
    "Withdrawn From Pipeline"                                 => { :stage => "pre",     :stage_type => "error"  },
    "Design Requested"                                        => { :stage => "designs", :stage_type => "normal" },
    "Alternate Design Requested"                              => { :stage => "designs", :stage_type => "warn"   },
    "VEGA Annotation Requested"                               => { :stage => "designs", :stage_type => "warn"   },
    "Design Not Possible"                                     => { :stage => "designs", :stage_type => "error"  },
    "Design Completed"                                        => { :stage => "designs", :stage_type => "normal" },
    "Vector Construction in Progress"                         => { :stage => "vectors", :stage_type => "normal" },
    "Vector Unsuccessful - Project Terminated"                => { :stage => "vectors", :stage_type => "error"  },
    "Vector Unsuccessful - Alternate Design in Progress"      => { :stage => "vectors", :stage_type => "warn"   },
    "Vector - Initial Attempt Unsuccessful"                   => { :stage => "vectors", :stage_type => "warn"   },
    "Vector Complete"                                         => { :stage => "vectors", :stage_type => "normal" },
    "Vector - DNA Not Suitable for Electroporation"           => { :stage => "vectors", :stage_type => "warn"   },
    "ES Cells - Electroporation in Progress"                  => { :stage => "cells",   :stage_type => "normal" },
    "ES Cells - Electroporation Unsuccessful"                 => { :stage => "cells",   :stage_type => "error"  },
    "ES Cells - No QC Positives"                              => { :stage => "cells",   :stage_type => "warn"   },
    "ES Cells - Targeting  Unsuccessful - Project Terminated" => { :stage => "cells",   :stage_type => "error"  },
    "ES Cells - Targeting Confirmed"                          => { :stage => "cells",   :stage_type => "normal" },
    "Mice - Microinjection in progress"                       => { :stage => "mice",    :stage_type => "normal" },
    "Mice - Germline transmission"                            => { :stage => "mice",    :stage_type => "normal" },
    "Mice - Genotype confirmed"                               => { :stage => "mice",    :stage_type => "normal" },
    "Regeneron Selected"                                      => { :stage => "pre",     :stage_type => "normal" },
    "Design Finished/Oligos Ordered"                          => { :stage => "designs", :stage_type => "normal" },
    "Parental BAC Obtained"                                   => { :stage => "vectors", :stage_type => "normal" },
    "Targeting Vector QC Completed"                           => { :stage => "vectors", :stage_type => "normal" },
    "Vector Electroporated into ES Cells"                     => { :stage => "vectors", :stage_type => "normal" },
    "ES cell colonies picked"                                 => { :stage => "cells",   :stage_type => "normal" },
    "ES cell colonies screened / QC no positives"             => { :stage => "cells",   :stage_type => "warn"   },
    "ES cell colonies screened / QC one positive"             => { :stage => "cells",   :stage_type => "warn"   },
    "ES cell colonies screened / QC positives"                => { :stage => "cells",   :stage_type => "normal" },
    "ES Cell Clone Microinjected"                             => { :stage => "cells",   :stage_type => "normal" },
    "Germline Transmission Achieved"                          => { :stage => "mice",    :stage_type => "normal" }
  }
  
  return status_definitions[ status ]
end
