
PHENO_IMG_LOC        = "#{Dir.pwd}/public/images/pheno_images"
PHENO_TEST_DESC_FILE = "#{Dir.pwd}/config/datasets/sanger-phenotyping/test_conf.json"
PHENO_ABR_LOC        = "#{Dir.pwd}/tmp/pheno_abr"

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
  orig_dir    = Dir.pwd
  path        = "#{PHENO_IMG_LOC}/#{colony_prefix}"
  test_conf   = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_conf") )
  test_images = {}
  
  dirs_to_ignore = [".","..","homviable"]
  
  if File.exists?(path) and File.directory?(path)
    Dir.foreach(path) do |test|
      unless dirs_to_ignore.include?(test)
        Dir.chdir("#{path}/#{test}")
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
    Dir.chdir(orig_dir)
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

# Function to set-up and @@ms.cache all of the required pheno data so that we 
# can easily build up links to and display pages from the images dumped 
# by Jacqui, and the pages dumped by Neil.
def setup_pheno_configuration
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
  
  unless @@ms.cache.fetch("sanger-phenotyping-abr_results")
    @@ms.cache.write( "sanger-phenotyping-abr_results", find_pheno_abr_results.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("sanger-phenotyping-test_names")
    attribute_map = {}
    @@ms.datasets_by_name[:"sanger-phenotyping"].dataset.attributes.each do |name,attribute|
      attribute_map[name] = attribute.display_name
    end
    @@ms.cache.write( "sanger-phenotyping-test_names", attribute_map.to_json, :expires_in => 12.hours )
  end
end

# Function to return an array of pheno tests for a given colony_prefix 
# that have a detailed phenotyping report page.
def pheno_links( colony_prefix )
  setup_pheno_configuration
  
  tests_to_link = []
  image_info = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-test_images") )[colony_prefix]
  abr_info   = JSON.parse( @@ms.cache.fetch("sanger-phenotyping-abr_results") )
  
  unless image_info.nil?
    tests_to_link = image_info.keys
  end
  
  if abr_info.include?(colony_prefix)
    tests_to_link.push("abr")
  end
  
  return tests_to_link
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
  search_data            = nil
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