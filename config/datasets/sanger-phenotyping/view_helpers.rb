
# Constants defining where our static data lives...
file_path            = File.expand_path(File.dirname(__FILE__))
PHENO_IMG_LOC        = "#{file_path}/../../../public/images/pheno_images"
PHENO_ABR_LOC        = "#{file_path}/../../../tmp/pheno_abr"
PHENO_TEST_DESC_FILE = "#{file_path}/test_conf.json"

# Constants for connecting to MIG
MIG_ORACLE_USER     = "eucomm_vector"
MIG_ORACLE_PASSWORD = "eucomm_vector"
MIG_ORACLE_DB       = "migp_ha.world"

require "oci8"
@@mig_dbh = OCI8.new(MIG_ORACLE_USER, MIG_ORACLE_PASSWORD, MIG_ORACLE_DB)

# Function to run through the pheno test images directory (supplied by Jacqui) 
# and returns a hash like so:
# colony_prefix => { pheno_test => {images to display} }
def find_pheno_images
  pheno_test_images = {}
  
  if File.exists?(PHENO_IMG_LOC) and File.directory?(PHENO_IMG_LOC)
    Dir.foreach(PHENO_IMG_LOC) do |colony_prefix|
      unless colony_prefix =~ /\.|\.\./
        pheno_test_images[colony_prefix] = pheno_images_for_colony(colony_prefix)
      end
    end
  end
  
  return pheno_test_images
end

# Utility function for find_pheno_images to do the actual work
# of listing all of the images found for each pheno test.
def pheno_images_for_colony( colony_prefix )
  path        = "#{PHENO_IMG_LOC}/#{colony_prefix}"
  test_conf   = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_conf") )
  test_images = {}
  
  dirs_to_ignore = [".","..","homviable"]
  
  if File.exists?(path) and File.directory?(path)
    Dir.chdir(path) do |colony_dir|
      Dir.foreach(".") do |test|
        if File.directory?(test) and !dirs_to_ignore.include?(test)
          Dir.chdir("#{path}/#{test}") do |test_dir|
            images_to_display = {}
            
            # Now to see if these images have been listed as for display...
            Dir.glob("*.{png,jpg,jpeg}").each do |found_image|
              # First, strip the file extension and strip off any 
              # prepended colony prefix...
              image_match  = found_image.match(/^(.+)\.\w+$/)[1]
              prefix_match = image_match.match(/^\w{4}-(\w+)$/)
              if prefix_match then image_match = prefix_match[1] end
              
              test_conf.keys.each do |pipeline|
                if test_conf[pipeline][test] and test_conf[pipeline][test]["image_lookup"][image_match]
                  images_to_display[image_match] = {
                    "file" => found_image,
                    "desc" => test_conf[pipeline][test]["image_lookup"][image_match]
                  }
                end
              end
            end
            
            test_images[ test ] = images_to_display
          end
        end
      end
    end
  end

  return test_images
end

# Function to run through the ABR pheno test directory (supplied by Neil) and 
# return a list of colonies with a webpage detailing thier phenotyping results.
def find_pheno_abr_results
  colonies_with_data = []
  
  if File.exists?(PHENO_ABR_LOC) and File.directory?(PHENO_ABR_LOC)
    Dir.foreach(PHENO_ABR_LOC) do |colony_prefix|
      if ( colony_prefix =~ /^\w\w\w\w$/ )
        if File.directory?("#{PHENO_ABR_LOC}/#{colony_prefix}") and File.exists?("#{PHENO_ABR_LOC}/#{colony_prefix}/ABR/index.shtml")
          colonies_with_data.push(colony_prefix)
        end
      end
    end
  end
  
  return colonies_with_data
end

# Utility function to grab/dump all of the data from a given table 
# in an Oracle database and return it as either:
# - an array of hashes (keyed by column name)
# - a hash of hashes, keyed by the value defined in the 'group_by' column
def dump_oracle_table( dbh, table, group_by=nil, where=nil )
  data    = []
  columns = []
  
  dbh.describe_table(table).columns.each do |column|
    columns.push(column.name)
  end
  
  sql = "select #{columns.join(", ")} from #{table}"
  if where
    sql << " #{where}"
  end
  
  cursor = dbh.exec(sql)
  cursor.fetch do |row|
    data_row = {}
    columns.each_index do |i|
      if columns[i] == "ID"          then data_row[ columns[i] ] = row[i].to_int
      elsif row[i].is_a?(BigDecimal) then data_row[ columns[i] ] = row[i].to_f
      else                                data_row[ columns[i] ] = row[i]
      end
    end
    data.push(data_row)
  end
  
  if group_by
    grouped_data = {}
    data.each do |hash|
      if grouped_data[ hash[ group_by ] ] === nil
        grouped_data[ hash[ group_by ] ] = []
      end
      grouped_data[ hash[ group_by ] ].push( hash )
    end
    data = grouped_data
  end
  
  return data
end

# Function to set-up and @@ms.cache all of the required pheno data so that we 
# can easily build up links to and display pages from the images dumped 
# by Jacqui, and the pages dumped by Neil.
def setup_pheno_configuration
  pheno_dataset = @@ms.datasets_by_name[:"sanger-phenotyping"].dataset
  expre_dataset = @@ms.datasets_by_name[:"sanger-wholemount_expression"].dataset
  
  unless @@ms.cache.fetch("sanger-phenotyping-test_conf")
    pheno_conf = JSON.load( File.new( PHENO_TEST_DESC_FILE, "r" ) )
    
    # Seperate the "images" out into two data structures - an 
    # array to preserve the order to display the images in, and 
    # a hash for looking up the image descriptions
    pheno_conf.each do |pipeline,pipeline_data|
      pipeline_data.each do |test,test_data|
        ordered_images = []
        image_lookup   = {}
        
        test_data["images"].each do |image|
          unless image.keys[0].empty?
            image_lookup[ "#{image.keys[0]}" ] = image[ image.keys[0] ]
            ordered_images.push( "#{image.keys[0]}" )
          end
        end
        
        test_data["image_lookup"]   = image_lookup
        test_data["ordered_images"] = ordered_images
      end
    end
    
    @@ms.cache.write( "sanger-phenotyping-test_conf", pheno_conf.to_json, :expires_in => 12.hours )
  end

  unless @@ms.cache.fetch("sanger-phenotyping-test_images")
    @@ms.cache.write( "sanger-phenotyping-test_images", find_pheno_images.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-homviable_results")
    homviable_results = dump_oracle_table( @@mig_dbh, "mig.rep_hom_lethality_vw", "COLONY_PREFIX" )
    @@ms.cache.write( "sanger-phenotyping-homviable_results", homviable_results.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-fertility_results_lookup")
    fertility_results = {}
    raw_results       = dump_oracle_table(
      @@mig_dbh,
      "mig.rep_mating_summary_vw",
      "COLONY_PREFIX",
      "where (FATHER_GENOTYPE_STATUS = 'Homozygous' or MOTHER_GENOTYPE_STATUS = 'Homozygous')"
    )
    
    raw_results.each do |colony,data|
      fertility_results[colony] = true
      @@ms.cache.write( "sanger-phenotyping-fertility_results_#{colony}", data.to_json, :expires_in => 12.hours )
    end
    
    @@ms.cache.write( "sanger-phenotyping-fertility_results_lookup", fertility_results.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-wholemount_expression_results_lookup")
    expression_results       = {}
    expression_results_cache = {}
    
    raw_results = expre_dataset.search(
      :process_results => true,
      :attributes => [
        "colony_prefix",
        "colony_name",
        "mouse_id",
        "mouse_name",
        "cohort_name",
        "age_in_weeks",
        "birth_date",
        "gender",
        "strain",
        "genotype",
        "pipeline",
        "comments",
        "anaesthetic",
        "adrenal_gland",
        "bone",
        "brain",
        "brown_adipose_tissue",
        "cartilage",
        "colon",
        "eye",
        "heart",
        "kidney",
        "large_intestine",
        "liver",
        "lung",
        "mammary_gland",
        "mesenteric_lymph_node",
        "nasal_epithelia",
        "oesophagus",
        "oral_epithelia",
        "ovaries",
        "oviduct",
        "pancreas",
        "peripheral_nervous_system",
        "peyers_patch",
        "prostate",
        "skeletal_muscle",
        "skin",
        "small_intestine",
        "spinal_cord",
        "spleen",
        "stomach",
        "testis",
        "thymus",
        "trachea",
        "urinary_system",
        "uterus",
        "vas_deferens",
        "vascular_system",
        "white_adipose_tissue"
      ]
    )
    
    raw_results.each do |result|
      expression_results[ result['colony_prefix'] ] = true
      if expression_results_cache[ result['colony_prefix'] ].nil?
        expression_results_cache[ result['colony_prefix'] ] = []
      end
      expression_results_cache[ result['colony_prefix'] ].push(result)
    end
    
    expression_results_cache.each do |colony_prefix,data|
      @@ms.cache.write( "sanger-phenotyping-wholemount_expression_results_#{colony_prefix}", data.to_json, :expires_in => 12.hours )
    end
    
    @@ms.cache.write( "sanger-phenotyping-wholemount_expression_results_lookup", expression_results.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-abr_results")
    @@ms.cache.write( "sanger-phenotyping-abr_results", find_pheno_abr_results.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-test_names")
    attribute_map = {}
    pheno_dataset.attributes.each do |name,attribute|
      attribute_map[name] = attribute.display_name
    end
    @@ms.cache.write( "sanger-phenotyping-test_names", attribute_map.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-heatmap")
    attributes_to_fetch = @@ms.datasets_by_name[:"sanger-phenotyping"].attributes
    attributes_to_fetch.push("marker_symbol")
    
    heat_map = []
    results = pheno_dataset.search( :attributes => attributes_to_fetch, :process_results => true )
    
    results.sort_by { |r| r["marker_symbol"] }.each do |result|
      result["allele_name"] = @@ms.datasets_by_name[:"sanger-phenotyping"].fix_superscript_text_in_attribute(result["allele_name"])
      heat_map.push(result)
    end
    
    @@ms.cache.write( "sanger-phenotyping-heatmap", heat_map.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-pheno_links")
    pheno_links = {}
    
    image_info      = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_images") )
    abr_info        = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-abr_results") )
    homviable_info  = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-homviable_results") )
    fertility_info  = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-fertility_results_lookup") )
    wholemount_info = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-wholemount_expression_results_lookup") )
    
    results = pheno_dataset.search( :attributes => ["colony_prefix"], :process_results => true )
    results.each do |result|
      colony_prefix = result["colony_prefix"]
      pheno_links[colony_prefix] = []
      
      unless image_info[colony_prefix].nil?
        image_info[colony_prefix].keys.each do |test|
          pheno_links[colony_prefix].push(test)
        end
      end
      
      if abr_info.include?(colony_prefix) then pheno_links[colony_prefix].push("abr") end
      if homviable_info[colony_prefix]    then pheno_links[colony_prefix].push("homozygote-viability") end
      if fertility_info[colony_prefix]    then pheno_links[colony_prefix].push("fertility") end
      if wholemount_info[colony_prefix]   then pheno_links[colony_prefix].push("adult-expression") end
    end
    
    @@ms.cache.write( "sanger-phenotyping-pheno_links", pheno_links.to_json, :expires_in => 12.hours )
  end
end

# Function to return an array of pheno tests for a given colony_prefix 
# that have a detailed phenotyping report page.
def pheno_links( colony_prefix, result_data=nil )
  setup_pheno_configuration
  links = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-pheno_links") )[colony_prefix]
  return links
end

# Template helper function to map the status descriptions retrived from MIG into 
# a CSS class that is used to draw the heat map
def css_class_for_test(status_desc)
  case status_desc
  when /Done but not considered interesting/i then "no_significant_difference"
  when /Considered interesting/i              then "significant_difference"
  when /Not applicable/i                      then "not_applicable"
  when /Early indication/i                    then "early_indication_of_possible_phenotype"
  when /Complete and data/i                   then "completed_data_available"
  else                                             "test_not_done"
  end
end

# Utility function to retrieve all of the data from the mart for a 
# given colony_prefix
def search_mart_by_colony_prefix(colony_prefix)
  search_data            = []
  search_data_from_cache = @@ms.cache.fetch("pheno_details_page_search:#{colony_prefix}")
  
  if search_data_from_cache
    search_data = JSON.parse(search_data_from_cache)
  else
    search_data = @@ms.datasets_by_name[:"sanger-phenotyping"].dataset.search(
      :filters         => { "colony_prefix" => colony_prefix },
      :attributes      => @@ms.datasets_by_name[:"sanger-phenotyping"].attributes,
      :process_results => true
    )
    @@ms.cache.write( "pheno_details_page_search:#{colony_prefix}", search_data.to_json, :expires_in => 12.hours )
  end
  
  return search_data
end
