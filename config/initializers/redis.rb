require 'redis'
require 'redis/connection/hiredis'
require_relative '../../lib/redis_pool'
require 'yaml'

redis_config = begin
  config = open(File.join(File.dirname(__FILE__), "..", "redis.yml.erb")).read
  YAML.load(ERB.new(config).result)[settings.environment.to_s]
end

$redis_pool = RedisPool.new(redis_config['nodes'])
