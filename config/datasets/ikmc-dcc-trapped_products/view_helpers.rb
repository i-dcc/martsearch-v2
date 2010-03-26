
# Simple function to return a URL to be used in a href tag 
# for order buttons on TIGM projects.
def trapped_products_tigm_order_url( clones, result_data )
  url =  "http://www.tigm.org/cgi-bin/tigminfo.cgi"
  url << "?survey=IKMC%20Website"
  url << "&mgi1=#{result_data["index"]["mgi_accession_id_key"]}"
  url << "&gene1=#{result_data["index"]["marker_symbol"]}"
  url << "&comments1=#{clones[0]}"
  return url
end

# Link URL generator for TIGM clones linking to NCBI.
def trapped_products_tigm_ncbi_url( clone )
  url =  "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi"
  url << "?cmd=Search&db=nucgss&doptcmdl=GenBank"
  url << "&term=%22#{clone}%22"
  return url
end
