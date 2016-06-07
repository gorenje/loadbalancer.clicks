# encoding: UTF-8
require_relative '../test_helper'

class RedirectTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @queue = RedisQueue.new($redis_pool)
    @queue.clear!
  end

  context "basic" do
    should "test_adid_redirect" do
      unchanged_cl_data = {
        :campaign     => "test",
        :adgroup      => "adgroup",
        :ad           => "ad",
        :network      => "test",
        :user_id      => "1"
      }

      cl = CampaignLink.
        create(unchanged_cl_data.
               merge({
                       :device       => "ios",
                       :campaign_url => "http://www.example.org/",
                       :target_url   => {"ios" => "http://example.org/ios"},
                       :country      => "DE",
                       :attribution_window_fingerprint => 10,
                       :attribution_window_idfa        => 100,
                     }))

      unchanged_cl_data["campaign_link_id"] = cl.id.to_s

      adid = '44566636-6BC5-48DE-B4AE-7DF9DF06B356'
      get("/click/#{cl.id}/go", { :adid => adid },
          { 'HTTP_USER_AGENT' => 'iPhone'})

      assert_redirect_to("ios")

      assert_equal 1, @queue.size
      click_details = @queue.pop.first.split

      assert_equal "iPhone", click_details.last
      params = CGI.parse(click_details[-2])

      unchanged_cl_data.each do |key, value|
        assert_equal(value, params[key.to_s].first, "Mismatch: #{key}")
      end
      assert_equal 'eb2e4ebe9bf98f8c92efc5f2cb468b18', params["lookup_key"].first
      assert_equal adid, params["idfa_comb"].first
    end
  end
end
