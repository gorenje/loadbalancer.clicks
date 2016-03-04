require 'geoip'

$geoip ||= GeoIP.new(File.join(File.dirname(__FILE__),"..","..","geoip.dat"))
