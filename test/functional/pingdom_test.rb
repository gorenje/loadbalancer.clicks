# encoding: UTF-8
require_relative '../test_helper'

class PingdomTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  def setup
    @queue = RedisQueue.new($redis_pool)
    @queue.clear!
  end

  context "basics" do
    should "handle check request" do
      get("/check")
      assert last_response.ok?
      assert_equal "OK", last_response.body
      assert_equal 0, @queue.size
    end
  end
end
