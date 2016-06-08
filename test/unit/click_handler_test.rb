# encoding: UTF-8
require_relative '../test_helper'

class ClickHandlerTest < Minitest::Test

  context "campaign link cache" do
    should "update if no campaign link available" do
      CampaignLink.delete_all
      assert_raises(NoMethodError) do
        ClickHandler.new({:id => 1}, OpenStruct.new)
      end

      cl = generate_campaign_link(:adgroup => "test")
      assert_nil $cam_lnk_cache[cl.id]

      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal "test", clh.adgroup

      assert_equal cl, $cam_lnk_cache[cl.id]
    end

    should "compute correct attribution window - idfa" do
      # attribution windows are minutes, so 1440 becomes one day.
      cl = generate_campaign_link(:attribution_window_idfa => 1440)
      clh = ClickHandler.new({:id => cl.id, :adid => SecureRandom.uuid},
                             OpenStruct.new)
      assert_equal 1, (clh.valid_till - clh.created_at).to_i
    end

    should "compute correct attribution window - fingerprint" do
      # attribution windows are minutes, so 1440 becomes one day.
      cl = generate_campaign_link(:attribution_window_fingerprint => 1440)
      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal 1, (clh.valid_till - clh.created_at).to_i
    end
  end
end
