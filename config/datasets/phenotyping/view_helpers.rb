
@@pheno_img_loc        = "#{Dir.pwd}/public/images/pheno_images"
@@pheno_test_desc_file = "#{Dir.pwd}/config/datasets/phenotyping/test_conf.json"
@@pheno_abr_loc        = "#{Dir.pwd}/tmp/pheno_abr"

# Class to generically describe a phenotyping test, takes a JSON 
# configuration object to set itsef up...
class PhenoTest
  attr_reader :slug, :name, :description, :parameter_groups

  def initialize( conf )
    @slug              = conf["slug"]
    @name              = conf["name"]
    @description       = conf["description"]
    @parameter_groups  = []

    conf["parameter_groups"].each do |param_conf|
      @parameter_groups.push( PhenoTestParameterGroup.new(param_conf) )
    end
  end
end

# Helper class to generically describe a group of phenotyping test 
# parameters as they will be represented on the report pages.
class PhenoTestParameterGroup
  attr_reader :name, :description, :images, :ordered_images

  def initialize( conf )
    @name           = conf["name"]
    @description    = conf["description"]
    @images         = {}
    @ordered_images = []

    conf["images"].each do |image|
      unless image.keys[0].empty?
        @images[ "#{image.keys[0]}" ] = image[ image.keys[0] ]
        @ordered_images.push( "#{image.keys[0]}" )
      end
    end
  end

  def images_to_render?( test_images=[] )
    displayed_images = []

    test_images.each do |test_image|
      # Strip the ".png",".jpg",".jpeg" etc from the file name...
      match = test_image.match(/^(.+)\.\w+$/)
      if self.ordered_images.include?( match[1] )
        displayed_images.push( test_image )
      end
    end
    
    return displayed_images
  end
end

# Function to run through the pheno test images directory (supplied by Jacqui) 
# and returns a hash like so:
# colony_prefix => { pheno_test => [images found] }
def find_pheno_images
  pheno_test_images = {}
  
  if File.exists?(@@pheno_img_loc) and File.directory?(@@pheno_img_loc)
    Dir.foreach(@@pheno_img_loc) do |colony_prefix|
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
  path        = "#{@@pheno_img_loc}/#{colony_prefix}"
  test_images = {}

  if File.exists?(path) and File.directory?(path)
    Dir.foreach(path) do |test_dir|
      unless test_dir =~ /\.|\.\./
        Dir.chdir("#{path}/#{test_dir}")
        test_images[ test_dir ] = Dir.glob("*.{png,jpg,jpeg}")
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
  
  if File.exists?(@@pheno_abr_loc) and File.directory?(@@pheno_abr_loc)
    Dir.foreach(@@pheno_abr_loc) do |colony_prefix|
      if ( colony_prefix =~ /^\w\w\w\w$/ )
        if File.directory?("#{@@pheno_abr_loc}/#{colony_prefix}") and File.exists?("#{@@pheno_abr_loc}/#{colony_prefix}/ABR/index.shtml")
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
  unless @@ms.cache.fetch("pheno_test_renders")
    pheno_conf         = JSON.load( File.new( @@pheno_test_desc_file, "r" ) )
    pheno_test_renders = {}
    
    pheno_conf.each do |pipeline,pipeline_tests|
      pheno_test_renders[pipeline] = {}
      pipeline_tests.each do |test,conf|
        pheno_test_renders[pipeline][test] = PhenoTest.new( conf )
      end
    end
    
    @@ms.cache.write( "pheno_test_renders", Marshal.dump(pheno_test_renders), :expires_in => 12.hours )
  end

  unless @@ms.cache.fetch("pheno_test_images")
    @@ms.cache.write( "pheno_test_images", find_pheno_images.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("pheno_abr_results")
    @@ms.cache.write( "pheno_abr_results", find_pheno_abr_results.to_json, :expires_in => 12.hours )
  end
  
  unless @@ms.cache.fetch("pheno_test_names")
    attribute_map = {}
    @@ms.datasets_by_name[:phenotyping].dataset.attributes.each do |name,attribute|
      attribute_map[name] = attribute.display_name
    end
    @@ms.cache.write( "pheno_test_names", attribute_map.to_json, :expires_in => 12.hours )
  end
end

# Function to return an array of pheno tests for a given colony_prefix 
# that have a detailed phenotyping report page.
def pheno_links( colony_prefix )
  setup_pheno_configuration
  
  tests_to_link = []
  image_info = JSON.parse( @@ms.cache.fetch("pheno_test_images") )[colony_prefix]
  abr_info   = JSON.parse( @@ms.cache.fetch("pheno_abr_results") )
  
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
    search_data = @@ms.datasets_by_name[:phenotyping].dataset.search(
      :filters         => { "colony_prefix" => colony_prefix },
      :attributes      => @@ms.datasets_by_name[:phenotyping].attributes,
      :process_results => true
    )
    @@ms.cache.write( "pheno_details_page_search:#{colony_prefix}", search_data.to_json, :expires_in => 12.hours )
  end
  
  return search_data
end