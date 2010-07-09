
def europhenome_link_url( opts={} )
  url  = "http://www.europhenome.org/databrowser/viewer.jsp?"
  url_opts = {
    'set'                        => 'true',
    'm'                          => 'true',
    'l'                          => opts[:europhenome_id],
    'zygosity'                   => opts[:zygosity],
    'x'                          => opts[:sex].titlecase,
    'p'                          => opts[:test_id],
    "pid_#{opts[:parameter_id]}" => 'on',
    'compareLines'               => 'View+Data'
  }
  
  opts_array = []
  url_opts.each do |key,value|
    opts_array.push("#{key}=#{value}")
  end
  
  return url + opts_array.join("&")
end
