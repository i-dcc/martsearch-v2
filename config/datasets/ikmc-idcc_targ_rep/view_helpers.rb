
def idcc_targ_rep_get_progressbar_info( project )
  if project['mouse_available']
    return { "vectors" => "normal", "cells" => "normal", "mice" => "normal" }
  end
  
  if project['escell_available']
    return { "vectors" => "normal", "cells" => "normal", "mice" => "incomp" }
  end
  
  if project['vector_available']
    return { "vectors" => "normal", "cells" => "incomp", "mice" => "incomp" }
  end
  
  # Nothing available - should not happen.
  return { "vectors" => "incomp", "cells" => "incomp", "mice" => "incomp" }
end

# Link URL generator for ordering products.
def idcc_targ_rep_product_order_url( project, result_data, order_type )
  url = ""
  
  pipeline_name     = project['pipeline_name']
  mgi_accession_id  = project['mgi_accession_id'][4..-1]
  project_id        = project['ikmc_project_id']
  marker_symbol     = result_data['index']['marker_symbol']
  
  if pipeline_name === "KOMP-CSD"
    case order_type
    when "vectors"
      url = "http://www.komp.org/vectorOrder.php?projectid=#{project_id}"
    when "cells"
      url = "http://www.komp.org/orders.php?project=CSD#{project_id}&amp;product=1"
    else
      url = "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
    end
  
  elsif pipeline_name === "KOMP-Regeneron"
    case order_type
    when "vectors"
      url = "http://www.komp.org/vectorOrder.php?projectid=#{project_id}"
    when "cells"
      url = "http://www.komp.org/orders.php?project=#{project_id}&amp;product=1"
    else
      url = "http://www.komp.org/geneinfo.php?project=#{project_id}"
    end
  
  elsif pipeline_name === "EUCOMM"
    case order_type
    when "vectors"
      url = "http://www.eummcr.org/final_vectors.php?mgi_id=#{mgi_accession_id}"
    when "cells"
      url = "http://www.eummcr.org/es_cells.php?mgi_id=#{mgi_accession_id}"
    when "mice"
      url = "http://www.emmanet.org/mutant_types.php?keyword=#{marker_symbol}%25EUCOMM&select_by=InternationalStrainName&search=ok"
    else
      url = "http://www.eummcr.org/order.php"
    end
  
  elsif pipeline_name === "NorCOMM"
    url = "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
  end
  
  return url
end