require 'maxminddb'

$geoip ||=
  MaxMindDB.new(File.join(File.dirname(__FILE__),"..","..","geoip.dat"))
