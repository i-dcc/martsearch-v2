["/project/:id","/project/?"].each do |path|
  get path do
    project_id  = params[:id]
    
    @current    = "home"
    @page_title = "Report for project #{project_id}"
    
    cached_data = @@ms.cache.fetch("project-report-#{project_id}")
    if cached_data.nil? or params[:fresh] == "true"
      @data = { 'project_id' => project_id }
      @data.update( get_common_data(project_id) )
      @data.update( get_vectors_and_cells(project_id) )
      @data.update( get_mice(@data['marker_symbol']) ) if @data['marker_symbol']
      @data.update( order_buttons_url(@data) )
      @data.update( get_pipeline_stage( @data['status']) ) if @data['status']
      
      @@ms.cache.write("project-report-#{project_id}", Marshal.dump(@data), :expires_in => 3.hours )
    else
      @data = Marshal.load(cached_data)
    end
    
    if params[:wt] == "json"
      content_type "application/json"
      return @data.to_json
    else
      erubis :project_report
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
  
  return results[0] if results
  return {}
end

# Will query IDCC targ rep mart
def get_vectors_and_cells( project_id )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/ikmc-idcc_targ_rep/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters => { 'ikmc_project_id' => project_id },
    :attributes => [
      'allele_id', 'design_id', 'mutation_subtype',
      'cassette', 'backbone', 'targeting_vector', 'intermediate_vector',
      'allele_symbol_superscript', 'escell_clone', 'parental_cell_line',
      'floxed_start_exon'
    ],
    :process_results => true
  })
  
  data = {}
  
  results.each do |result|
    if data.empty?
      data.update(
        'intermediate_vectors' => [],
        'targeting_vectors'    => [],
        'conditionals'         => { 'cells' => [] },
        'non_conditionals'     => { 'cells' => [] }
      )
    end
    
    design_type =
      case result['mutation_subtype']
        when 'conditional_ready'        then 'Conditional (Frameshift)'
        when 'deletion'                 then 'Deletion'
        when 'targeted_non_conditional' then 'Targeted, Non-Conditional'
        else ''
      end
    
    allele_image = "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/allele-image"
    genbank_file = "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/escell-clone-genbank-file"
    
    #
    #   Intermediate Vectors
    #
    data['intermediate_vectors'].push(
      'name'        => result['intermediate_vector'],
      'design_id'   => result['design_id'],
      'design_type' => design_type,
      'floxed_exon' => result['floxed_start_exon']
    ) unless result['mutation_subtype'] == 'targeted_non_conditional'
    
    
    #
    #   Targeting Vectors
    #
    data['targeting_vectors'].push(
      'name'         => result['targeting_vector'],
      'design_id'    => result['design_id'],
      'design_type'  => design_type,
      'cassette'     => result['cassette'],
      'backbone'     => result['backbone'],
      'floxed_exon'  => result['floxed_start_exon'],
      'genbank_file' => "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
    ) unless result['mutation_subtype'] == 'targeted_non_conditional'
    
    
    #
    #   Non-Conditionals
    #
    if ['targeted_non_conditional', 'deletion'].include? result['mutation_subtype']
      data['non_conditionals'].update(
        'design_type'  => design_type,
        'allele_image' => allele_image,
        'genbank_file' => genbank_file
      )
      
      next if result['escell_clone'].nil? or result['escell_clone'].empty?
      
      data['non_conditionals']['cells'].push(
        'name'                      => result['escell_clone'],
        'allele_symbol_superscript' => result['allele_symbol_superscript'],
        'parental_cell_line'        => result['parental_cell_line'],
        'targeting_vector'          => result['targeting_vector']
      )
    
    
    #
    #   Conditionals
    #
    else
      data['conditionals'].update(
        'design_type'  => design_type,
        'allele_image' => allele_image,
        'genbank_file' => genbank_file
      )
      
      next if result['escell_clone'].nil? or result['escell_clone'].empty?
      
      data['conditionals']['cells'].push(
        'name'                      => result['escell_clone'],
        'allele_symbol_superscript' => result['allele_symbol_superscript'],
        'parental_cell_line'        => result['parental_cell_line'],
        'targeting_vector'          => result['targeting_vector']
      )
    end
  end
  
  unless data.empty?
    data['intermediate_vectors'].uniq!
    data['targeting_vectors'].uniq!
    data['conditionals']['cells'].uniq!
    data['non_conditionals']['cells'].uniq!
  end
  
  return data
end

# Will query Kermits mart
def get_mice( marker_symbol )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/sanger-kermits/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters => { 'marker_symbol' => marker_symbol, 'active' => '1' },
    :attributes => ['status', 'allele_name', 'escell_clone', 'escell_strain', 'escell_line'],
    :process_results => true
  })
  results.reject! { |result| result['status'].nil? }
  
  unless results.empty?
    return { 'mice' => results }
  else
    return {}
  end
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
