
# Constants defining where our static data lives...
file_path                   = File.expand_path(File.dirname(__FILE__))
SANGER_PHENO_IMG_LOC        = "#{file_path}/../../../public/images/pheno_images"
SANGER_PHENO_ABR_LOC        = "#{file_path}/../../../tmp/pheno_abr"
SANGER_PHENO_TEST_DESC_FILE = "#{file_path}/test_conf.json"
SANGER_PHENO_WT_LACZ_IMG    = "#{file_path}/adult_expression_background_staining.csv"

# Function to run through the pheno test images directory (supplied by Jacqui) 
# and returns a hash like so:
# colony_prefix => { pheno_test => {images to display} }
def sanger_phenotyping_pheno_images
  pheno_test_images = {}
  
  if File.exists?(SANGER_PHENO_IMG_LOC) and File.directory?(SANGER_PHENO_IMG_LOC)
    Dir.foreach(SANGER_PHENO_IMG_LOC) do |colony_prefix|
      unless colony_prefix =~ /\.|\.\./
        pheno_test_images[colony_prefix] = sanger_phenotyping_pheno_images_for_colony(colony_prefix)
      end
    end
  end
  
  return pheno_test_images
end

# Utility function for sanger_phenotyping_pheno_images to do the actual work
# of listing all of the images found for each pheno test.
def sanger_phenotyping_pheno_images_for_colony( colony_prefix )
  path        = "#{SANGER_PHENO_IMG_LOC}/#{colony_prefix}"
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
def sanger_phenotyping_find_pheno_abr_results
  colonies_with_data = []
  
  if File.exists?(SANGER_PHENO_ABR_LOC) and File.directory?(SANGER_PHENO_ABR_LOC)
    Dir.foreach(SANGER_PHENO_ABR_LOC) do |colony_prefix|
      if ( colony_prefix =~ /^\w\w\w\w$/ )
        if File.directory?("#{SANGER_PHENO_ABR_LOC}/#{colony_prefix}") and File.exists?("#{SANGER_PHENO_ABR_LOC}/#{colony_prefix}/ABR/index.shtml")
          colonies_with_data.push(colony_prefix)
        end
      end
    end
  end
  
  return colonies_with_data
end

# Function to set-up and @@ms.cache all of the required pheno data so that we 
# can easily build up links to and display pages from the images dumped 
# by Jacqui, and the pages dumped by Neil.
def sanger_phenotyping_setup
  pheno_dataset     = @@ms.datasets_by_name[:"sanger-phenotyping"].dataset
  expre_dataset     = @@ms.datasets_by_name[:"sanger-wholemount_expression"].dataset
  microscopy_img_ds = Biomart::Dataset.new( "http://www.sanger.ac.uk/htgt/biomart", { :name => "microscopy_images" } )
  
  unless @@ms.cache.fetch("sanger-phenotyping-test_conf")
    pheno_conf = JSON.load( File.new( SANGER_PHENO_TEST_DESC_FILE, "r" ) )
    
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
    @@ms.cache.write( "sanger-phenotyping-test_images", sanger_phenotyping_pheno_images.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-homviable_lookup")
    homviable_results = {}
    homviable_lookup  = {}
    homviable_data    = pheno_dataset.search(
      :process_results => true,
      :attributes => [
        "hom_viability_colony_prefix",
        "genetic_background",
        "colony_ppl",
        "female_wt",
        "male_wt",
        "female_het",
        "male_het",
        "female_hom",
        "male_hom",
        "wt_ratio",
        "het_ratio",
        "hom_ratio",
        "total_untested",
        "total_failed",
        "total_wt",
        "total_het",
        "total_hom",
        "total_wt_het_hom",
        "wt_expected",
        "het_expected",
        "hom_expected",
        "chi_sqred",
        "p_value",
        "significant"
      ]
    )
    
    homviable_data.each do |result|
      unless result['hom_viability_colony_prefix'].nil?
        homviable_results[ result['hom_viability_colony_prefix'] ] = result
      end
    end
    
    homviable_results.each do |colony,data|
      homviable_lookup[colony] = true
      @@ms.cache.write( "sanger-phenotyping-homviable_results_#{colony}", data.to_json, :expires_in => 12.hours )
    end
    
    @@ms.cache.write( "sanger-phenotyping-homviable_lookup", homviable_lookup.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-fertility_lookup")
    fertility_results = {}
    fertility_lookup  = {}
    
    fertility_data    = pheno_dataset.search(
      :process_results => true,
      :attributes => [
        "fertility_colony_prefix",
        "mir_project_licence",
        "breeding_name",
        "breeding_category",
        "father",
        "father_age_at_setup",
        "mother",
        "mother_age_at_setup",
        "father_genotype",
        "mother_genotype",
        "setup_date",
        "separation_date",
        "length_of_mating_weeks",
        "number_of_pups_born",
        "number_of_pups_weaned",
        "total_number_of_litters_born",
        "number_prewean_deaths",
        "number_prewean_culls"
      ]
    )
    
    fertility_data.each do |result|
      unless result['fertility_colony_prefix'].nil?
        if fertility_results[ result['fertility_colony_prefix'] ].nil?
          fertility_results[ result['fertility_colony_prefix'] ] = []
        end
        fertility_results[ result['fertility_colony_prefix'] ].push(result)
      end
    end
    
    fertility_results.each do |colony,data|
      fertility_lookup[colony] = true
      @@ms.cache.write( "sanger-phenotyping-fertility_results_#{colony}", data.to_json, :expires_in => 12.hours )
    end
    
    @@ms.cache.write( "sanger-phenotyping-fertility_lookup", fertility_lookup.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-wholemount_expression_lookup")
    expression_results = {}
    expression_lookup  = {}
    
    ticklist_data = expre_dataset.search(
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
        "gall_bladder",
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
        "parathyroid",
        "peripheral_nervous_system",
        "peyers_patch",
        "pituitary_gland",
        "prostate",
        "skeletal_muscle",
        "skin",
        "small_intestine",
        "spinal_cord",
        "spleen",
        "stomach",
        "testis",
        "thymus",
        "thyroid",
        "trachea",
        "urinary_system",
        "uterus",
        "vas_deferens",
        "vascular_system",
        "white_adipose_tissue"
      ]
    )
    
    image_data = microscopy_img_ds.search(
      :process_results => true,
      :filters => {
        "image_type" => "Wholemount Expression",
        "genotype"   => ["Heterozygous","Homozygous","Hemizygous"]
      },
      :attributes => [
        "colony_prefix",
        "mouse_id",
        "gender",
        "genotype",
        "genotype_locked",
        "age_at_death",
        "tissue",
        "image_type",
        "description",
        "annotations",
        "comments",
        "full_image_url"
      ]
    )
    
    ticklist_data.each do |result|
      expression_lookup[ result["colony_prefix"] ] = true
      if expression_results[ result["colony_prefix"] ].nil?
        expression_results[ result["colony_prefix"] ] = {
          "ticklist"      => [],
          "adult_images"  => [],
          "embryo_images" => []
        }
      end
      expression_results[ result["colony_prefix"] ]["ticklist"].push(result)
    end
    
    image_data.sort{ |a,b| "#{a['tissue']}-#{a['gender']}" <=> "#{b['tissue']}-#{b['gender']}" }.each do |result|
      if expression_results[ result["colony_prefix"] ] != nil and result["tissue"] != nil
        # get the thumbnail URL (as the one in the mart can be flakey...)
        result["thumbnail_url"] = result["full_image_url"].sub("\.(\w+)$","thumb.\1")

        if result["tissue"].match("Embryo")
          expression_results[ result["colony_prefix"] ]["embryo_images"].push(result)
        else
          expression_results[ result["colony_prefix"] ]["adult_images"].push(result)
        end
      end
    end
    
    expression_results.each do |colony,data|
      @@ms.cache.write( "sanger-phenotyping-wholemount_expression_results_#{colony}", data.to_json, :expires_in => 12.hours )
    end
    
    @@ms.cache.write( "sanger-phenotyping-wholemount_expression_lookup", expression_lookup.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-expression_background_staining")
    background_images   = []
    mouse_ids           = {}
    selected_images_csv = File.read(SANGER_PHENO_WT_LACZ_IMG)
    
    parsed_csv = []
    if CSV.const_defined? :Reader
      parsed_csv = CSV.parse( selected_images_csv, "," ) # Ruby < 1.9 CSV code
    else
      parsed_csv = CSV.parse( selected_images_csv, { :col_sep => "," } ) # Ruby >= 1.9 CSV code
    end
    
    parsed_csv.shift
    parsed_csv.each do |image_info|
      mouse_ids[ image_info[2] ] = [] if mouse_ids[ image_info[2] ].nil?
      mouse_ids[ image_info[2] ].push({ "order" => image_info[0], "image_id" => image_info[3]})
    end
    
    image_data = microscopy_img_ds.search(
      :process_results => true,
      :filters => {
        "image_type" => "Wildtype Expression",
        "genotype"   => "Wildtype",
        "mouse_id"   => mouse_ids.keys
      },
      :attributes => [
        "colony_prefix",
        "mouse_id",
        "gender",
        "genotype",
        "genotype_locked",
        "age_at_death",
        "tissue",
        "image_type",
        "description",
        "annotations",
        "comments",
        "full_image_url"
      ]
    )
    
    image_data.each do |result|
      save_this_img = false
      
      mouse_ids[ result["mouse_id"] ].each do |img_conf|
        if result["full_image_url"].match( img_conf["image_id"] )
          save_this_img           = true
          result["thumbnail_url"] = result["full_image_url"].sub("\.(\w+)$","thumb.\1")
          result["order"]         = img_conf["order"]
        end
      end
      
      background_images[ result["order"].to_i - 1 ] = result if save_this_img
    end
    
    @@ms.cache.write( "sanger-phenotyping-expression_background_staining", background_images.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-abr_results")
    @@ms.cache.write( "sanger-phenotyping-abr_results", sanger_phenotyping_find_pheno_abr_results.to_json, :expires_in => 12.hours )
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
    homviable_info  = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-homviable_lookup") )
    fertility_info  = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-fertility_lookup") )
    wholemount_info = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-wholemount_expression_lookup") )
    
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
def sanger_phenotyping_details_links( colony_prefix, result_data=nil )
  sanger_phenotyping_setup
  links = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-pheno_links") )[colony_prefix]
  return links
end

# Template helper function to map the status descriptions retrived from MIG into 
# a CSS class that is used to draw the heat map
def sanger_phenotyping_css_class_for_test(status_desc)
  case status_desc
  when "Test complete and data\/resources available"  then "completed_data_available"
  when "Test complete and considered interesting"     then "significant_difference"
  when "Test complete but not considered interesting" then "no_significant_difference"
  when "Early indication of possible phenotype"       then "early_indication_of_possible_phenotype"
  when /^Test not performed or applicable/i           then "not_applicable"
  when "Test abandoned"                               then "test_abandoned"
  else                                                     "test_pending"
  end
end

# Utility function to retrieve all of the data from the mart for a 
# given colony_prefix
def sanger_phenotyping_search_by_colony(colony_prefix)
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

def sanger_phenotyping_test_groupings
  {
    "Viability, Fertility and Expression" => {
      :pipelines => [ "P1/2", "EUMODIC P1/2", "Mouse GP", "Sanger MGP" ],
      :tests     => [
        "homozygote_viability",
        "recessive_lethal",
        "fertility",
        "embryo_expression",
        "adult_expression",
        "general_observations"
      ]
    },
    "Cardiovascular and Metabolism" => {
      :pipelines => [ "P1/2", "EUMODIC P1/2" ],
      :tests     => [
        "body_weight_curve_high_fat_diet",
        "dysmorphology",
        "blood_pressure",
        "indirect_calorimetry",
        "ip_gtt",
        "dexa",
        "x_ray_imaging",
        "core_temperature",
        "heart_weight",
        "heart_histology",
        "fasted_clinical_chemistry"
      ]
    },
    "Behaviour, Sensory and Blood" => {
      :pipelines => [ "P1/2", "EUMODIC P1/2" ],
      :tests     => [
        "body_weight_curve_normal_chow",
        "open_field",
        "modified_shirpa",
        "grip_strength",
        "rotarod",
        "prepulse_inhibition",
        "hot_plate",
        "abr",
        "eye_morphology",
        "histology",
        "full_clinical_chemistry",
        "plasma_immunoglobulins",
        "haematology",
        "peripheral_blood_lymphocytes",
        "micronuclei_naive"
      ]
    },
    "Comprehensive Phenotyping Pipeline" => {
      :pipelines => [ "Mouse GP", "Sanger MGP" ],
      :tests     => [
        "body_weight_curve_high_fat_diet",
        "hair_follicle",
        "open_field",
        "modified_shirpa",
        "grip_strength",
        "dysmorphology",
        "hot_plate",
        "indirect_calorimetry",
        "ip_gtt",
        "abr",
        "dexa",
        "x_ray_imaging",
        "core_temperature",
        "eye_morphology",
        "heart_weight",
        "heart_histology",
        "histology",
        "full_clinical_chemistry",
        "plasma_immunoglobulins",
        "haematology",
        "peripheral_blood_lymphocytes",
        "micronuclei_naive"
      ]
    },
    "Infectious Challenges" => {
      :pipelines => [ "P1/2", "EUMODIC P1/2", "Mouse GP", "Sanger MGP" ],
      :tests     => [
        "salmonella_challenge",
        "citrobacter_challenge"
      ]
    },
    "Collaborations" => {
      :pipelines => [ "P1/2", "EUMODIC P1/2", "Mouse GP", "Sanger MGP" ],
      :tests     => [
        "micronuclei_irradiated",
        "insulin",
        "skin_screen",
        "brain_histology"
      ]
    }
  }
end

def sanger_phenotyping_test_groupings_order
  [
    "Viability, Fertility and Expression",
    "Cardiovascular and Metabolism",
    "Behaviour, Sensory and Blood",
    "Comprehensive Phenotyping Pipeline",
    "Infectious Challenges",
    "Collaborations"
  ]
end