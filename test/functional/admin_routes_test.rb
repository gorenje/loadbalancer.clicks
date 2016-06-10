# encoding: UTF-8
require_relative '../test_helper'

class AdminRoutesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  def setup
    @queue = RedisQueue.new($redis_pool)
    @queue.clear!
  end

  context "admin routes" do
    should "handle apple images" do
      get("/apple-fubar.png")
      assert_last_response_was_gif
      assert_equal 0, @queue.size
    end

    should "handle favicon" do
      get("/favicon.ico")
      assert_last_response_was_gif
      assert_equal 0, @queue.size
    end

    should "handle robots.txt" do
      get("/robots.txt")
      assert last_response.ok?
      assert_equal "User-agent: *\nDisallow: /\n", last_response.body
      assert_equal 0, @queue.size
    end
  end
end
