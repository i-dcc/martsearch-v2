#!/usr/bin/env ruby -wKU

##
## Utility script to read in Jacqui's test descriptions
## and create the skeleton of the 'test_conf.json' file.
##

require "rubygems"
require "csv"
require "pp"

require "#{File.dirname(__FILE__)}/../../../../lib/string.rb"

##
## Constants
##

# Used to map the spreadsheet descriptions to our objects...
TEST_MAP = {
  "Adult Expression"                      => "adult-expression",
  "Blood pressure"                        => "blood-pressure",
  "Body weight curve (HFD)"               => "body-weight-curve-high-fat-diet",
  "Body weight curve (normal chow)"       => "body-weight-curve-normal-chow",
  "Core temp/Stress induced hyperthermia" => "core-temperature",
  "Citrobacter Challenge"                 => "citrobacter-challenge",
  "DEXA"                                  => "dexa",
  "Dysmorphology"                         => "dysmorphology",
  "Eye Morphology"                        => "eye-morphology",
  "Fasted clinical chemsitry"             => "fasted-clinical-chemistry",
  "Full clinical chemsitry"               => "full-clinical-chemistry",
  "Grip Strength"                         => "grip-strength",
  "Haematology"                           => "haematology",
  "Hair follicle cycling"                 => "hair-follicle",
  "Heart Weights"                         => "heart-weight",
  "Hot plate"                             => "hot-plate",
  "Indirect Calorimetry"                  => "indirect-calorimetry",
  "Insulin"                               => "insulin",
  "ip-GTT"                                => "ip-gtt",
  "Modified SHIRPA"                       => "modified-shirpa",
  "Open Field"                            => "open-field",
  "Rotarod"                               => "rotarod",
  "Salmonella Challenge"                  => "salmonella-challenge",
  "Skin Screen"                           => "skin-screen",
  "X-ray imaging"                         => "x-ray-imaging"
}

# Presentable names for some of the tests, if the name isn't here,
# we default to using what was in the spreadsheet.
TEST_NAMES = {
  "body-weight-curve-high-fat-diet" => "Body Weight Curve (High Fat Diet)",
  "citrobacter-challenge"           => "Citrobacter Rodentium Challenge",
  "dexa"                            => "Dual Energy X-Ray Absorptiometry (DEXA)",
  "heart-weight"                    => "Heart Weight",
  "ip-gtt"                          => "ip-GTT",
  "modified-shirpa"                 => "Modified SHIRPA",
  "salmonella-challenge"            => "Salmonella Typhimurium Challenge",
  "x-ray-imaging"                   => "X-Ray Imaging"
}

##
## Read in the descriptions... Columns expected:
##   - Assay Name
##   - Pipeline
##   - Description
##   - Second Description
##

file_text = ""
File.new("descriptions.csv","r").each do |line|
  file_text << line
end

if CSV.const_defined? :Reader
  # Ruby < 1.9 CSV code
  descriptions = CSV.parse( file_text, "," )
else
  # Ruby >= 1.9 CSV code
  descriptions = CSV.parse( file_text, { :col_sep => "," } )
end

##
## Now run through the descriptions and build up the conf structure...
##

test_conf = {
  "sanger-mgp"           => {},
  "eumodic-pipeline-1-2" => {},
  "expression"           => {}
}

descriptions.each do |row|
  if TEST_MAP[row[0]]
    test_slug               = TEST_MAP[row[0]]
    test_description        = row[2].gsub("\n","<br />")
    test_second_description = row[3]
    
    unless test_second_description.nil?
      test_second_description.gsub!("\n","<br />")
    end
    
    test_name = ""
    if TEST_NAMES[test_slug]
      test_name = TEST_NAMES[test_slug]
    else
      test_name = row[0].titlecase
    end
    
    test_pipeline = case row[1]
    when /Mouse GP/ then "sanger-mgp"
    when /P1\/2/    then "eumodic-pipeline-1-2"
    when /MGP Pipe/ then "eumodic-pipeline-1-2"
    when /Expre/    then "expression"
    end
    
    test_conf[test_pipeline][test_slug] = {
      "slug"               => test_slug,
      "name"               => test_name,
      "description"        => test_description,
      "second_description" => test_second_description,
      "images"             => []
    }
  else
    puts "Found an error with this line in the CSV!!!!"
    require "pp"
    pp row
  end
end

##
## Finally, print out the config to file...
##

File.open("test_conf.json","w") do |f|
  
  f.write "{\n"
  pipelines = test_conf.keys.sort
  pipelines.each do |pipeline|
    f.write "  \"#{pipeline}\": {\n"

    tests = test_conf[pipeline].keys.sort
    tests.each do |test|
      f.write "    \"#{test}\": {\n"

        options = test_conf[pipeline][test].keys.sort
        options.each do |option|
          if test_conf[pipeline][test][option].is_a?(String)
            f.write "      \"#{option}\": \"#{test_conf[pipeline][test][option]}\""
          elsif test_conf[pipeline][test][option].is_a?(Array)
            f.write "      \"#{option}\": []"
          else
            f.write "      \"#{option}\": \"\""
          end
          if option == options.last then f.write "\n" else f.write ",\n" end
        end

      if test == tests.last then f.write "    }\n" else f.write "    },\n" end
    end

    if pipeline == pipelines.last then f.write "  }\n" else f.write "  },\n" end
  end
  f.write "}\n"
  
end

