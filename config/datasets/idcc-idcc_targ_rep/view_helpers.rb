
# This method defines the possible statuses for each project 
# and returns a project_status hash for a given project entry.
def idcc_targ_rep_get_status_info( mol_struct, ikmc_project )
  unless ikmc_project
    if mol_struct['conditional_clones'].empty? and mol_struct['nonconditional_clones'].empty?
      return { :stage => "vectors", :type => "normal" }
    else
      return { :stage => "cells", :type => "normal" }
    end
  end
  
  status_definitions = case mol_struct["pipeline_name"]
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
  
  return status_definitions[ ikmc_project["status"] ]
end
