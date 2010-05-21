require "bigdecimal"

def europhenome_tests_per_row
  return 7
end

def europhenome_test_mapping
  {
    "ESLIM_001_001" => "Dysmorphology",
    "ESLIM_022_001" => "Body Weight",
    "ESLIM_002_001" => "Non-Invasive Blood Pressure",
    "ESLIM_003_001" => "Calorimetry",
    "ESLIM_004_001" => "Simplified IPGTT",
    "ESLIM_005_001" => "DEXA",
    "ESLIM_006_001" => "X-Ray",
    "ESLIM_021_001" => "Fasted Clinical Chemistry",
    "ESLIM_020_001" => "Heart Weight/Tibia Length",
  
    "ESLIM_007_001" => "Open Field",
    "ESLIM_008_001" => "Modified SHIRPA",
    "ESLIM_009_001" => "Grip-Strength",
    "ESLIM_010_001" => "Rotarod",
    "ESLIM_011_001" => "Acoustic Startle & PPI",
    "ESLIM_012_001" => "Hot Plate",
    "ESLIM_013_001" => "Opthalmoscope",
    "ESLIM_014_001" => "Slit Lamp",
    "ESLIM_015_001" => "Clinical Chemistry",
    "ESLIM_016_001" => "Haematology",
    "ESLIM_017_001" => "ANP",
    "ESLIM_018_001" => "FACs Analysis",
    "ESLIM_019_001" => "Immunoglobulin Concentration",
    "ESLIM_022_001" => "Body Weight",
  
    "ESLIM_010_001" => "Rotarod",
    "ESLIM_006_001" => "X-Ray",
    "GMC_900_001"   => "Dysmorphology (GMC)",
    "GMC_901_001"   => "Slit Lamp (GMC)",
    "GMC_904_001"   => "Allergy (GMC)",
    "GMC_905_001"   => "Haematology (GMC)",
    "GMC_908_001"   => "Bodyweight (GMC)",
    "GMC_910_001"   => "ECG (Electrocardiogram) (GMC)",
    "GMC_914_001"   => "Food efficiency (GMC)",
    "GMC_915_001"   => "Fundoscopy (GMC)",
    "GMC_916_001"   => "Holeboard (GMC)",
    "GMC_918_001"   => "Blood Pressure (GMC)",
    "GMC_919_001"   => "Slit Lamp 2 (GMC)",
    "GMC_920_001"   => "Spontaneous Breathing (GMC)",
    "GMC_912_001"   => "ERG (Electroretinogram) (GMC)",
    "GMC_923_001"   => "Shirpa (GMC)",
    "GMC_902_001"   => "Eye Size (GMC)",
    "GMC_913_001"   => "FACS (GMC)",
    "GMC_906_001"   => "Clinical chemistry (GMC)",
    "GMC_909_001"   => "pDexa (GMC)",
    "GMC_911_001"   => "ELISA (GMC)",
    "GMC_921_001"   => "Grip Strength (GMC)",
    "GMC_922_001"   => "Rotarod (GMC)",
    "GMC_917_001"   => "Nociception Hotplate (GMC)",
  
    "M-G-P_022_001" => "Body Weight",
    "M-G-P_001_001" => "Dysmorphology",
    "M-G-P_003_001" => "Indirect Calorimetry",
    "M-G-P_005_001" => "Dexa-scan Analysis",
    "M-G-P_013_001" => "Ophthalmoscope",
    "M-G-P_014_001" => "Slit Lamp",
    "M-G-P_016_001" => "Haematology",
    "M-G-P_020_001" => "Heart Dissection",
    "M-G-P_009_001" => "Grip Strength",
    "M-G-P_012_001" => "Hot Plate",
    "M-G-P_004_001" => "IPGTT",
    "M-G-P_007_001" => "Open Field",
    "M-G-P_008_001" => "Modified SHIRPA",
    "M-G-P_006_001" => "X-Ray"
  }
end

def europhenome_pipelines
  {
    "EUMODIC Pipeline 1" => [
      "ESLIM_001_001",
      "ESLIM_022_001",
      "ESLIM_002_001",
      "ESLIM_003_001",
      "ESLIM_004_001",
      "ESLIM_005_001",
      "ESLIM_006_001",
      "ESLIM_021_001",
      "ESLIM_020_001"
    ],
    "EUMODIC Pipeline 2" => [
      "ESLIM_007_001",
      "ESLIM_008_001",
      "ESLIM_009_001",
      "ESLIM_010_001",
      "ESLIM_011_001",
      "ESLIM_012_001",
      "ESLIM_013_001",
      "ESLIM_014_001",
      "ESLIM_015_001",
      "ESLIM_016_001",
      "ESLIM_017_001",
      "ESLIM_018_001",
      "ESLIM_019_001",
      "ESLIM_022_001"
    ],
    "GMC Pipeline" => [
      "ESLIM_010_001",
      "ESLIM_006_001",
      "GMC_900_001",
      "GMC_901_001",
      "GMC_904_001",
      "GMC_905_001",
      "GMC_908_001",
      "GMC_910_001",
      "GMC_914_001",
      "GMC_915_001",
      "GMC_916_001",
      "GMC_918_001",
      "GMC_919_001",
      "GMC_920_001",
      "GMC_912_001",
      "GMC_923_001",
      "GMC_902_001",
      "GMC_913_001",
      "GMC_906_001",
      "GMC_909_001",
      "GMC_911_001",
      "GMC_921_001",
      "GMC_922_001",
      "GMC_917_001"
    ],
    "MGP Pipeline" => [
      "M-G-P_022_001",
      "M-G-P_001_001",
      "M-G-P_003_001",
      "M-G-P_005_001",
      "M-G-P_013_001",
      "M-G-P_014_001",
      "M-G-P_016_001",
      "M-G-P_020_001",
      "M-G-P_009_001",
      "M-G-P_012_001",
      "M-G-P_004_001",
      "M-G-P_007_001",
      "M-G-P_008_001",
      "M-G-P_006_001"
    ]
  }
end

def europhenome_link_url( europhenome_id, sex, parameter_id, result_ids )
  url  = "http://www.europhenome.org/databrowser/viewer.jsp?"
  opts = {
    "set"          => "true",
    "m"            => "true",
    "l"            => europhenome_id,
    "x"            => sex,
    "p"            => parameter_id,
    "compareLines" => "View+Data"
  }
  
  result_ids.each do |id|
    opts["pid_#{id}"] = "on"
  end
  
  opts_array = []
  opts.each do |key,value|
    opts_array.push("#{key}=#{value}")
  end
  
  return url + opts_array.join("&")
end

def europhenome_empress_link_url( pipeline_name, parameter_id )
  url =  "http://empress.har.mrc.ac.uk/viewempress/?pipelineprocedure="
  
  pipeline_param = case "#{pipeline_name}~#{europhenome_test_mapping()[parameter_id]}"
  when "EUMODIC Pipeline 2~Open Field"             then "EUMODIC Pipeline 2~Open-Field"
  when "EUMODIC Pipeline 2~Acoustic Startle & PPI" then "EUMODIC Pipeline 2~Acoustic Startle%26PPI"
  when "MGP Pipeline~Haematology"                  then "MGP Pipeline~Haematology test"
  else
    "#{pipeline_name}~#{europhenome_test_mapping()[parameter_id]}"
  end
  
  url << pipeline_param.gsub(" ","+")
  return url
end