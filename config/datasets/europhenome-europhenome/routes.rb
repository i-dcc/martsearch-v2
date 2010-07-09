
##
## Read in the MP configuration file...
##

unless Module.const_defined?(:EUROPHENOME_MP_CONF)
  mp_conf_file = "#{MARTSEARCHR_PATH}/config/datasets/europhenome-europhenome/mp_conf.marshal"
  mp_conf = ""
  File.open( mp_conf_file, "r" ).each_line { |line| mp_conf << line }
  EUROPHENOME_MP_CONF = Marshal.load(mp_conf)
end