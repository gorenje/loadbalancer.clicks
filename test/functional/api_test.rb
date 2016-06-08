# encoding: UTF-8
require_relative '../test_helper'

class ApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @base_data = {
      :campaign     => "test",
      :adgroup      => "adgroup",
      :ad           => "ad",
      :network      => "test",
      :user_id      => "1"
    }
  end

  context "basic" do
    should "create new campaign link" do
      cl = generate_campaign_link(@base_data)
      CampaignLink.delete_all

      post("/api/1/create", { :campaign_link => cl.to_json })

      assert CampaignLink.find(cl.id)
      assert last_response.ok?
      assert_equal "ok", JSON.parse(last_response.body)["status"]
    end

    should "update existing campaign links" do
      cl = generate_campaign_link(@base_data)
      CampaignLink.delete_all

      post("/api/1/create", { :campaign_link => cl.to_json })
      assert last_response.ok?
      cl = CampaignLink.find(cl.id)
      assert "adgroup", cl.adgroup

      cl.adgroup = "fubar"
      post("/api/1/create", { :campaign_link => cl.to_json })
      assert last_response.ok?
      cl = CampaignLink.find(cl.id)
      assert "fubar", cl.adgroup

      assert_equal 1, CampaignLink.count
    end
  end

  context "secret key" do
    should "respond with 404 if no match" do
      add_to_env("API_SECRET_KEY" => "fubar") do
        cl = generate_campaign_link(@base_data)
        CampaignLink.delete_all

        post("/api/1/create", { :campaign_link => cl.to_json },
             { "X-API-SALT" => "nomatch"})
        assert last_response.not_found?
        assert_equal 0, CampaignLink.count
      end
    end

    should "respond with 404 if no match using pepper" do
      add_to_env("API_SECRET_KEY" => "fubar") do
        cl = generate_campaign_link(@base_data)
        CampaignLink.delete_all

        post("/api/1/create", { :campaign_link => cl.to_json, :pepper => "p" },
             { "X-API-SALT" => "nomatch"})
        assert last_response.not_found?
        assert_equal 0, CampaignLink.count
      end
    end

    should "work if ok" do
      add_to_env("API_SECRET_KEY" => "fubar") do
        cl = generate_campaign_link(@base_data)
        CampaignLink.delete_all

        str = cl.to_json
        p = Digest::SHA1.hexdigest("somesalt" + str + "fubar")
        post("/api/1/create", { :campaign_link => str, :pepper => p },
             { "X-API-SALT" => "somesalt"})
        assert last_response.ok?
        assert_equal 1, CampaignLink.count
      end
    end
  end
end
