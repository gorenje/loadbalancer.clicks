require 'bundler/setup'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/streaming'
require 'sinatra/reloader'
require 'cgi'
require 'json'
require 'oj_mimic_json'
require 'fast_blank'
require 'digest/md5'
require 'addressable/uri'

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

# RAILS_ENV is set via unicorn in production and used
# by test_helper to also set the environment.
set(:environment,   ENV['RAILS_ENV']) unless ENV['RAILS_ENV'].nil?
set :server,        :thin
set :port,          (ENV['PORT'] || 2343).to_i
set :public_folder, Proc.new { File.join(root, "public") }

# We do not really care about IP spoofing. In fact, it is a good
# way to test.
set :protection, :except => [:frame_options, :ip_spoofing]

set :logging, true
set :static, true

set :raise_errors, true
set :show_exceptions, false
set :dump_errors, true

if settings.environment == :development
  require 'pry'
end

Dir[File.join(File.dirname(__FILE__),'config', 'initializers','*.rb')].
  each { |a| require_relative a }

use Librato::Rack

require_relative 'lib/click_handler.rb'
require_relative 'lib/ruby_extensions.rb'
require_relative 'lib/exception_handling.rb'
use ExceptionHandling

# initial the view helpers
require_relative 'lib/helpers.rb'
helpers do
  include AdtekioTracking::Helpers
end

require_relative 'lib/redis_pool.rb'
require_relative 'lib/redis_queue.rb'

[
 ['routes'],
 ['models'],
].each do |path|
  Dir[File.join(File.dirname(__FILE__), path, '*.rb')].each { |f| require f }
end

# setup the campaign link cache
$refresh_cam_lnk_cache.call
