
##
## Read in the MP configuration file...
##

unless Module.const_defined?(:EUROPHENOME_MP_CONF)
  mp_conf_file = "#{MARTSEARCHR_PATH}/config/datasets/europhenome-europhenome/mp_conf.json"
  EUROPHENOME_MP_CONF = JSON.load( File.open( mp_conf_file, 'r' ) )
end