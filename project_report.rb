get "/project/:id" do
  @current    = "home"
  @page_title = "Report for project #{params[:id]}"
  @data       = get_data( params[:id] )
  
  erubis :project_report
end

def get_data( project_id )
  data = { :project_id => project_id }
  
  query_index( data, project_id ) # To get common data
  
  query_idcc_targ_rep_mart( data, project_id )
  query_ko_attempts_mart( data, project_id )
  query_kermits( data, project_id )
  
  return data
end

def query_index( data, project_id )
  results = @@ms.index.search( query = "ikmc_project_id:#{project_id}")
  index_results = results.values()[0]['index']

  data_wanted = ['colony_prefix', 'allele', 'product_status', 'vega_gene_id',
    'marker_symbol', 'mgi_accession_id', 'ensembl_gene_id'
  ]
  returned_hash = {}
  data_wanted.inject({}){|returned_hash, key| returned_hash.update( key.to_sym => index_results[key] )}
  
  data.update( returned_hash )
end

def query_idcc_targ_rep_mart( data, project_id )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/ikmc-idcc_targ_rep/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters => { 'ikmc_project_id' => project_id },
    :attributes => [
      'allele_id', 'pipeline', 'design_id', 'mutation_subtype',
      'cassette', 'backbone', 'targeting_vector', 'intermediate_vector',
      'allele_symbol_superscript', 'escell_clone', 'parental_cell_line',
      'floxed_start_exon'
    ],
    :process_results => true
  })
  
  results.each do |result|
    if not data.keys.include? :pipeline
      data.update({
        :pipeline               => result['pipeline'],
        :design_id              => result['design_id'],
        :cassette               => result['cassette'],
        :backbone               => result['backbone'],
        :floxed_exon            => result['floxed_start_exon'],
        :genbank_files_urls     => {
          :escell_clone     => "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/escell-clone-genbank-file",
          :targeting_vector => "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/targeting-vector-genbank-file"
        },
        :escell_clones          => { :conditionals => {}, :non_conditionals => {} },
        :targeting_vectors      => {},
        :intermediate_vectors   => {}
      })
    else
      design_type =
        case result['mutation_subtype']
        when 'conditional_ready'        then 'Conditional (Frameshift)'
        when 'deletion'                 then 'Deletion'
        when 'targeted_non_conditional' then 'Targeted, non-conditional'
        else ''
        end
      
      unless data[:targeting_vectors].keys.include? result['targeting_vector']
        data[:targeting_vectors][result['targeting_vector']] = { :design_type => design_type }
      end
      
      unless data[:intermediate_vectors].keys.include? result['intermediate_vector']
        data[:intermediate_vectors][result['intermediate_vector']] = { :design_type => design_type }
      end
      
      next if result['escell_clone'].nil? or result['escell_clone'].empty?
      
      if result['mutation_subtype'] == 'targeted_non_conditional'
        data[:escell_clones][:non_conditionals].update({
          result['escell_clone'] => {
            :allele_symbol_superscript  => result['allele_symbol_superscript'],
            :parental_cell_line                => result['parental_cell_line'],
            :targeting_vector           => result['targeting_vector']
          }
        })
        data[:escell_non_cond_img_link] = "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/allele-image"
      else
        data[:escell_clones][:conditionals].update({
          result['escell_clone'] => {
            :allele_symbol_superscript  => result['allele_symbol_superscript'],
            :parental_cell_line         => result['parental_cell_line'],
            :targeting_vector           => result['targeting_vector']
          }
        })
        data[:escell_cond_img_link] = "#{conf['attribution_link']}targ_rep/alleles/#{result['allele_id']}/allele-image"
      end
    end
  end
end

def query_ko_attempts_mart( data, project_id )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/ikmc-dcc-knockout_attempts/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters => { 'ikmc_project_id' => project_id },
    :attributes => [ 'status' ],
    :process_results => true
  })
  results.each { |result| data.update({ :status => result['status'] }) }
end

def query_kermits( data, project_id )
  conf    = JSON.load( File.new("#{File.dirname(__FILE__)}/config/datasets/sanger-kermits/config.json","r") )
  dataset = Biomart::Dataset.new( conf['url'], { :name => conf['dataset_name'] } )
  results = dataset.search({
    :filters => { 'colony_name' => data[:colony_prefix][0] },
    :attributes => ['marker_symbol', 'allele_name', 'escell_clone', 'escell_strain', 'escell_line'],
    :process_results => true
  })
  
  if results
    data.update({ :mice => [] })
    
    results.each do |result|
      data[:mice].push({
        :marker_symbol  => result['marker_symbol'],
        :allele_name    => result['allele_name'],
        :escell_clone   => result['escell_clone'],
        :escell_strain  => result['escell_strain'],
        :escell_line    => result['escell_line'],
      })
    end
  end
end