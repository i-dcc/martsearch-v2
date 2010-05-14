get "/project/:id" do
  project_id  = params[:id]
  
  @current    = "home"
  @page_title = "Report for project #{project_id}"
  @data = { 'project_id' => project_id }
  @data.update( get_common_data(project_id) )
  @data.update( get_vectors_and_cells(project_id) )
  @data.update( get_mice(@data['ensembl_gene_id']) ) if @data['ensembl_gene_id']
  @data.update( order_buttons_url(@data) )
  
  erubis :project_report
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
    
    # Intermediate Vectors
    data['intermediate_vectors'].push(
      'name'        => result['intermediate_vector'],
      'design_id'   => result['design_id'],
      'design_type' => design_type,
      'floxed_exon' => result['floxed_start_exon']
    ) unless result['mutation_subtype'] == 'targeted_non_conditional'
    
    # Targeting Vectors
    data['targeting_vectors'].push(
      'name'         => result['targeting_vector'],
      'design_id'    => result['design_id'],
      'design_type'  => design_type,
      'cassette'     => result['cassette'],
      'backbone'     => result['backbone'],
      'floxed_exon'  => result['floxed_start_exon'],
      'genbank_file' => "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
    ) unless result['mutation_subtype'] == 'targeted_non_conditional'
    
    # Non-Conditionals
    if result['mutation_subtype'] == 'targeted_non_conditional'
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
    
    # Conditionals
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
def get_mice( ensembl_gene_id )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/sanger-kermits/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters => { 'ensembl_gene_id' => ensembl_gene_id },
    :attributes => ['allele_name', 'escell_clone', 'escell_strain', 'escell_line'],
    :process_results => true
  })
  
  return { 'mice' => results } unless results.empty?
  return {}
end

def order_buttons_url( data )
  mgi_accession_id  = data['mgi_accession_id'][4..-1]
  pipeline          = data['pipeline']
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
