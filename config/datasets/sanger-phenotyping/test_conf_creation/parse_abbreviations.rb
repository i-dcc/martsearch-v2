#!/usr/bin/env ruby -wKU

##
## Utility script to read in Jacqui's image abbreviations
## and the phenotyping 'test_conf.json' and populate the images 
## sections with data from the csv file...
##

require "rubygems"
require "csv"
require "json"
require "pp"

require "#{File.dirname(__FILE__)}/../../../../lib/string.rb"

##
## Read in the test_conf.json and wipe out the image sections
##

test_conf = JSON.load( File.new( "test_conf.json", "r" ) )

test_conf.each do |pipeline,pipeline_tests|
  pipeline_tests.each do |test,test_data|
    test_data["images"] = []
  end
end

##
## Read in the abbreviations... Columns expected:
##   - Pipeline
##   - Image Description
##   - Phenotyping Test (as in the test_conf)
##   - Image Short-Code
##   - "or het or hom"
##

file_text = ""
File.new("abbreviations.csv","r").each do |line|
  file_text << line
end

if CSV.const_defined? :Reader
  # Ruby < 1.9 CSV code
  abbreviations = CSV.parse( file_text, "," )
else
  # Ruby >= 1.9 CSV code
  abbreviations = CSV.parse( file_text, { :col_sep => "," } )
end

##
## Now run through the abbreviations and build in the images...
##

abbreviations.each do |row|
  unless row[2] == "homviable"
    pipeline =  case row[0]
    when /Mouse GP/ then "sanger-mgp"
    when /P1\/2/    then "eumodic-pipeline-1-2"
    end
    
    test         = row[2]
    variable     = row[1].titlecase
    abbreviation = row[3]
    
    # Catch a common fook-up...
    if abbreviation === "carpalfusionwt"
      abbreviation = "carpalfusion"
      row[4]       = "w00t wibble blibble flip"
    end
    
    begin
      test_conf[pipeline][test]["images"].push({ abbreviation => variable })

      unless row[4].nil?
        ["wt","het","hom"].each do |append|
          test_conf[pipeline][test]["images"].push({ abbreviation+append => variable })
        end
      end
    rescue NoMethodError => error
      puts "Found an error with this line in the CSV!!!!"
      require "pp"
      pp row
    end
  end
end

##
## Finally, print out the JSON file... Sorry for the shittyness of this, 
## but we need readable JSON output at the end just in case a human needs to 
## edit this...
##

File.open("test_conf_with_images.json","w") do |f|
  
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
          else
            f.write "      \"#{option}\": #{test_conf[pipeline][test][option].to_json}"
          end
          if option == options.last then f.write "\n" else f.write ",\n" end
        end

      if test == tests.last then f.write "    }\n" else f.write "    },\n" end
    end

    if pipeline == pipelines.last then f.write "  }\n" else f.write "  },\n" end
  end
  f.write "}\n"
  
end
