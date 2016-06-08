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
  end
end
