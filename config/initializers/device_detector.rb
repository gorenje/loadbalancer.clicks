require 'device_detector'

DeviceDetector.configure do |config|
  config.max_cache_keys = 5_000
end
