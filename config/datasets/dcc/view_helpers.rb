
# This method defines the possible statuses for each project 
# and returns a project_status hash for a given project entry
def get_status_info( project )
  status_definitions = case project[:project]
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
      "Vector Unsuccessful - Alternate Design in Progres"       => { :stage => "vectors", :type => "warn"   },
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
  
  return status_definitions[ project[:status] ]
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
