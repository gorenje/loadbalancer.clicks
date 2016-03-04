require 'newrelic_rpm'
require 'newrelic-redis'

if settings.environment == :development
  # check localhost:2343/newrelic for request information
  require 'new_relic/rack/developer_mode'
  use NewRelic::Rack::DeveloperMode
end
