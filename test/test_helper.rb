ENV['RAILS_ENV']    = 'test' # ensures that settings.environment == 'test'
ENV['RACK_ENV']     = 'test'
ENV['IP']           = 'www.example.com'
ENV['PORT']         = '9999'
ENV['TZ']           = 'UTC'
ENV['DATABASE_URL'] = ENV['DATABASE_URL'] + "_test"

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
    old_stderr,old_stdout,stdout,stderr =
      $stderr, $stdout, StringIO.new, StringIO.new

    $stdout = stdout
    $stderr = stderr
    result = yield
    [result, stdout.string, stderr.string]
  ensure
    $stderr, $stdout = old_stderr, old_stdout
  end

  def assert_redirect_to(path, msg = nil)
    assert(last_response.redirect?,
           "Request was not redirect" + (msg ? " (#{msg})" : ""))
    assert_equal('http://example.org/%s' % [path],
                 last_response.headers["Location"],
                 "Redirect location didn't match"+ (msg ? " (#{msg})" : ""))
  end

  def assert_click_params(params, unchanged_cl_data, msg = nil)
    unchanged_cl_data.each do |key, value|
      assert_equal(value, params[key.to_s].first, "Mismatch: #{key}")
    end
  end

  def pop_click
    assert_equal 1, @queue.size, "Pop click didn't except this"
    click_details = @queue.pop.first.split
    [click_details, CGI.parse(click_details[-2])]
  end

  def generate_campaign_link(merge_data = {})
    CampaignLink.
      create({ :device       => "ios",
               :campaign_url => "http://www.example.org/",
               :target_url   => {
                 "ios"      => "http://example.org/ios",
                 "android"  => "http://example.org/android",
                 "fallback" => "http://example.org/fallback",
                 "default"  => "http://example.org/default",
               },
               :country      => "DE",
               :attribution_window_fingerprint => 10,
               :attribution_window_idfa        => 100,
             }.merge(merge_data))
  end

  def add_to_env(changes)
    changes.each { |k,v| ENV[k] = v }
    yield
  ensure
    changes.keys.each { |key| ENV.delete(key) }
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
