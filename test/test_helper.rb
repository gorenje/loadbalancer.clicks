ENV['RAILS_ENV'] = 'test' # ensures that settings.environment == 'test'
ENV['RACK_ENV']  = 'test'
ENV['IP']        = 'www.example.com'
ENV['PORT']      = '9999'
ENV['TZ']        = 'UTC'

require "bundler/setup"
require 'rack/test'
require 'shoulda'
require 'rr'
require 'hpricot'
# use binding.pry at any point of the tests to enter the pry shell
# and pock around the current object and state
#    https://github.com/pry/pry/wiki/Runtime-invocation
require 'pry'
require 'fakeweb'
require 'minitest/autorun'

require_relative '../lib/ruby_extensions.rb'
require_relative '../application.rb'

raise "Not Using Test Environment" if settings.environment != 'test'

FakeWeb.register_uri(:post, /metrics-api.librato.com/, :status => 200)

class Minitest::Test
  include RR::Adapters::TestUnit

  def silence_is_golden
    old_stderr,old_stdout,stdout,stderr = $stderr,$stdout,StringIO.new,
                                          StringIO.new
    $stdout = stdout
    $stderr = stderr
    result = yield
    [result, stdout.string, stderr.string]
  ensure
    $stderr, $stdout = old_stderr, old_stdout
  end

  def assert_redirect_to(path, msg = nil)
    assert last_response.redirect?, "Request was not redirect (#{msg})"
    assert_equal('http://example.org/%s' % [path],
                 last_response.headers["Location"], "Redirect location didn't match (#{msg}")
  end
end

class RedisQueue
  def pop(number_of_elements = 1)
    elements = pool.execute do |redis|
      redis.pipelined do |pipe|
        number_of_elements.times { pipe.lpop(key) }
      end
    end

    elements
  end
end
