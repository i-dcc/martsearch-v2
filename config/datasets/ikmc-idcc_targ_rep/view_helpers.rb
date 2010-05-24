
def idcc_targ_rep_get_progressbar_info( project )
  if project['mouse_available'] == '1'
    return { "vectors" => "normal", "cells" => "normal", "mice" => "normal" }
  end
  
  if project['escell_available'] == '1'
    return { "vectors" => "normal", "cells" => "normal", "mice" => "incomp" }
  end
  
  if project['vector_available'] == '1'
    return { "vectors" => "normal", "cells" => "incomp", "mice" => "incomp" }
  end
  
  if project['no_products_available'] and project['status']
    return { "vectors" => "normal", "cells" => "incomp", "mice" => "incomp" }
  end
  
  # Some other case
  return { "vectors" => "incomp", "cells" => "incomp", "mice" => "incomp" }
end

# Link URL generator for ordering products.
def idcc_targ_rep_product_order_url( project, result_data, order_type )
  url = ""
  
  pipeline          = project['pipeline']
  mgi_accession_id  = project['mgi_accession_id'][4..-1]
  project_id        = project['ikmc_project_id']
  marker_symbol     = result_data['index']['marker_symbol']
  
  if pipeline == "KOMP-CSD"
    case order_type
    when "vectors"
      url = "http://www.komp.org/vectorOrder.php?projectid=#{project_id}"
    when "cells"
      url = "http://www.komp.org/orders.php?project=CSD#{project_id}&amp;product=1"
    else
      url = "http://www.komp.org/geneinfo.php?project=CSD#{project_id}"
    end
  
  elsif pipeline == "KOMP-Regeneron"
    case order_type
    when "vectors"
      url = "http://www.komp.org/vectorOrder.php?projectid=#{project_id}"
    when "cells"
      url = "http://www.komp.org/orders.php?project=#{project_id}&amp;product=1"
    else
      url = "http://www.komp.org/geneinfo.php?project=#{project_id}"
    end
  
  elsif pipeline == "EUCOMM" or pipeline == "mirKO"
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
  
  elsif pipeline == "NorCOMM"
    url = "http://www.phenogenomics.ca/services/cmmr/escell_services.html"
  end
  
  return url
end