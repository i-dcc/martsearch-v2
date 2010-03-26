
# This method defines the possible statuses for each project 
# and returns a project_status hash for a given project entry.
def knockout_attempts_get_status_info( project )
  status_definitions = case project["pipeline_name"]
  when /EUCOMM|KOMP-CSD|NorCOMM/
    {
      "On Hold"                                                 => { :stage => "pre",     :type => "warn"   },
      "Transferred to NorCOMM"                                  => { :stage => "pre",     :type => "error"  },
      "Transferred to KOMP"                                     => { :stage => "pre",     :type => "error"  },
      "Withdrawn From Pipeline"                                 => { :stage => "pre",     :type => "error"  },
      "Design Requested"                                        => { :stage => "designs", :type => "normal" },
      "Alternate Design Requested"                              => { :stage => "designs", :type => "warn"   },
      "VEGA Annotation Requested"                               => { :stage => "designs", :type => "warn"   },
      "Design Not Possible"                                     => { :stage => "designs", :type => "error"  },
      "Design Completed"                                        => { :stage => "designs", :type => "normal" },
      "Vector Construction in Progress"                         => { :stage => "vectors", :type => "normal" },
      "Vector Unsuccessful - Project Terminated"                => { :stage => "vectors", :type => "error"  },
      "Vector Unsuccessful - Alternate Design in Progress"      => { :stage => "vectors", :type => "warn"   },
      "Vector - Initial Attempt Unsuccessful"                   => { :stage => "vectors", :type => "warn"   },
      "Vector Complete"                                         => { :stage => "vectors", :type => "normal" },
      "Vector - DNA Not Suitable for Electroporation"           => { :stage => "vectors", :type => "warn"   },
      "ES Cells - Electroporation in Progress"                  => { :stage => "cells",   :type => "normal" },
      "ES Cells - Electroporation Unsuccessful"                 => { :stage => "cells",   :type => "error"  },
      "ES Cells - No QC Positives"                              => { :stage => "cells",   :type => "warn"   },
      "ES Cells - Targeting  Unsuccessful - Project Terminated" => { :stage => "cells",   :type => "error"  },
      "ES Cells - Targeting Confirmed"                          => { :stage => "cells",   :type => "normal" },
      "Mice - Microinjection in progress"                       => { :stage => "mice",    :type => "normal" },
      "Mice - Germline transmission"                            => { :stage => "mice",    :type => "normal" },
      "Mice - Genotype confirmed"                               => { :stage => "mice",    :type => "normal" }
    }
  when "KOMP-Regeneron"
    {
      "Regeneron Selected"                          => { :stage => "pre",     :type => "normal" },
      "Design Finished/Oligos Ordered"              => { :stage => "designs", :type => "normal" },
      "Parental BAC Obtained"                       => { :stage => "vectors", :type => "normal" },
      "Targeting Vector QC Completed"               => { :stage => "vectors", :type => "normal" },
      "Vector Electroporated into ES Cells"         => { :stage => "vectors", :type => "normal" },
      "ES cell colonies picked"                     => { :stage => "cells",   :type => "normal" },
      "ES cell colonies screened / QC no positives" => { :stage => "cells",   :type => "warn"   },
      "ES cell colonies screened / QC one positive" => { :stage => "cells",   :type => "warn"   },
      "ES cell colonies screened / QC positives"    => { :stage => "cells",   :type => "normal" },
      "ES Cell Clone Microinjected"                 => { :stage => "cells",   :type => "normal" },
      "Germline Transmission Achieved"              => { :stage => "mice",    :type => "normal" }
    }
  end
  
  return status_definitions[ project["status"] ]
end

# This method encapsulates the logic needed to draw a project 
# progress bar based on the project_status hash passed to it.
def get_progressbar_info( project_status )
  progress = case project_status[:stage]
  when "pre"
    {
      "pre"     => project_status[:type],
      "designs" => "incomp",
      "vectors" => "incomp",
      "cells"   => "incomp",
      "mice"    => "incomp"
    }
  when "designs"
    {
      "pre"     => "normal",
      "designs" => project_status[:type],
      "vectors" => "incomp",
      "cells"   => "incomp",
      "mice"    => "incomp"
    }
  when "vectors"
    {
      "pre"     => "normal",
      "designs" => "normal",
      "vectors" => project_status[:type],
      "cells"   => "incomp",
      "mice"    => "incomp"
    }
  when "cells"
    {
      "pre"     => "normal",
      "designs" => "normal",
      "vectors" => "normal",
      "cells"   => project_status[:type],
      "mice"    => "incomp"
    }
  when "mice"
    {
      "pre"     => "normal",
      "designs" => "normal",
      "vectors" => "normal",
      "cells"   => "normal",
      "mice"    => project_status[:type]
    }
  else
    {
      "pre"     => "incomp",
      "designs" => "incomp",
      "vectors" => "incomp",
      "cells"   => "incomp",
      "mice"    => "incomp"
    }
  end
  
  return progress
end

# Simple function to return a URL to be used in a href tag 
# for order buttons on TIGM projects.
def tigm_order_url( project, result_data )
  url =  "http://www.tigm.org/cgi-bin/tigminfo.cgi"
  url << "?survey=IKMC%20Website"
  url << "&mgi1=#{result_data["index"]["mgi_accession_id_key"]}"
  url << "&gene1=#{result_data["index"]["marker_symbol"]}"
  url << "&comments1=#{project[0]}"
  return url
end

# Link URL generator for TIGM clones linking to NCBI.
def tigm_ncbi_url( clone )
  url =  "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi"
  url << "?cmd=Search&db=nucgss&doptcmdl=GenBank"
  url << "&term=%22#{clone}%22"
  return url
end

# Link URL generator for ordering products.
def product_order_url( project, result_data, order_type )
  url = ""
  
  if project["pipeline_name"] === "KOMP-CSD"
    case order_type
    when "vectors"
      url = "http://www.komp.org/vectorOrder.php?projectid=#{project["project_id"]}"
    when "cells"
      url = "http://www.komp.org/orders.php?project=CSD#{project["project_id"]}&amp;product=1"
    else
      url = "http://www.komp.org/geneinfo.php?project=CSD#{project["project_id"]}"
    end
  elsif project["pipeline_name"] === "KOMP-Regeneron"
    case order_type
    when "vectors"
      url = "http://www.komp.org/vectorOrder.php?projectid=#{project["project_id"]}"
    when "cells"
      url = "http://www.komp.org/orders.php?project=#{project["project_id"]}&amp;product=1"
    else
      url = "http://www.komp.org/geneinfo.php?project=#{project["project_id"]}"
    end
  elsif project["pipeline_name"] === "EUCOMM"
    mgi_id = project['mgi_accession_id'].split('MGI:')[1]
    
    case order_type
    when "vectors"
      url = "http://www.eummcr.org/final_vectors.php?mgi_id=#{mgi_id}"
    when "cells"
      url = "http://www.eummcr.org/es_cells.php?mgi_id=#{mgi_id}"
    when "mice"
      url = "http://www.emmanet.org/mutant_types.php?keyword=#{result_data["index"]["marker_symbol"]}%25EUCOMM&select_by=InternationalStrainName&search=ok"
    else
      url = "http://www.eummcr.org/order.php"
    end
  elsif project["pipeline_name"] === "NorCOMM"
    url = "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
  elsif project["pipeline_name"] === "MirKO"
    url = "TO BE DEFINED"
  end
  
  return url
end
