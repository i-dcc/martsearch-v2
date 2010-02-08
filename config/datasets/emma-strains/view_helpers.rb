
# Helper function to give a "plain" english explaination 
# of the mutation types coming from the emma mart
def emma_strain_type( main_type, sub_type )
  main_type_dict = {
    "CH" => "Chromosomal Anomalies",
    "GT" => "GT",
    "IN" => "Induced Mutant Strains",
    "SP" => "Spontaneous",
    "TG" => "Transgenic Strains",
    "TM" => "Targeted Mutant Strains",
    "XX" => "Other"
  }
  
  sub_type_dict = {
    "DEL"  => "Deletion",
    "DUP"  => "Duplication",
    "TRL"  => "Translocation",
    "XX"   => "",
    "CH"   => "Chemically-Induced",
    "Xray" => "Radiation-Induced",
    "CM"   => "Conditional Mutation",
    "KI"   => "",
    "KO"   => "Knockout",
    "OTH"  => "Other Targeted Mutation",
    "PM"   => "Point Mutation",
    "TC"   => "",
    "TNC"  => ""
  }
  
  string_to_return = ""
  string_to_return << main_type_dict[main_type]
  
  if sub_type and sub_type_dict[sub_type] and sub_type_dict[sub_type] != ""
    string_to_return << " : #{sub_type_dict[sub_type]}"
  end
  
  return string_to_return
end