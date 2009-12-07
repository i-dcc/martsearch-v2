
@@pheno_img_loc = "#{Dir.pwd}/public/images/pheno_results"
@@pheno_test_desc_file = "#{Dir.pwd}/config/datasets/phenotyping/test_conf.json"

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
  location          = @@pheno_img_loc

  if File.exists?(location) && File.directory?(location)
    Dir.foreach(location) do |colony_prefix|
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

  if File.exists?(path) && File.directory?(path)
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

# Function to set-up and @@ms.cache all of the required pheno data so that we 
# can easily build up links to and display pages from the images dumped 
# by Jacqui.
def setup_pheno_configuration
  # @@ms.cache the objects for rendering the phenotyping report pages.
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

  # @@ms.cache the list of colonies with tests and images associated with them.
  unless @@ms.cache.fetch("pheno_test_images")
    @@ms.cache.write( "pheno_test_images", find_pheno_images.to_json, :expires_in => 12.hours )
  end
end

# Function to return an array of pheno tests for a given colony_prefix 
# that have a detailed phenotyping report page.
def pheno_links( colony_prefix )
  setup_pheno_configuration
  colony_info = JSON.parse( @@ms.cache.fetch( "pheno_test_images" ) )[colony_prefix]
  if colony_info.nil?
    return []
  else
    return colony_info.keys
  end
end
