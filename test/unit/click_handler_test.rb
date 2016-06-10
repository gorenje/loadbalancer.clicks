# encoding: UTF-8
require_relative '../test_helper'

class ClickHandlerTest < Minitest::Test

  context "campaign link cache" do
    should "update if no campaign link available" do
      CampaignLink.delete_all
      assert_raises(NoMethodError) do
        ClickHandler.new({:id => 1}, OpenStruct.new).click_to_kafka_string
      end

      cl = generate_campaign_link(:adgroup => "test")
      assert_nil $cam_lnk_cache[cl.id]

      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal "test", clh.camlink.adgroup

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

  context "lookup key" do
    should "compute the lookup key - using adid" do
      p   = { :adid => SecureRandom.uuid }
      req = OpenStruct.new({})
      clh = ClickHandler.new(p,req)

      exp = Digest::MD5.hexdigest(p[:adid].downcase)
      assert clh.has_idfa_comb?
      assert_equal exp, clh.lookup_key
    end

    should "compute the lookup key - using ip" do
      p   = {}
      req = OpenStruct.new({
                             :ip         => '127.0.0.1',
                             :user_agent => "iPhone"
                           })
      clh = ClickHandler.new(p,req)

      # assuming the device dectector returns 'ios' for the platform
      exp = Digest::MD5.hexdigest("#{req.ip}.ios".downcase)
      assert !clh.has_idfa_comb?
      assert_equal exp, clh.lookup_key
    end
  end

  context "url_for" do
    should "take default if set" do
      turl = {
        "default" => "fubar"
      }
      cl = generate_campaign_link(:target_url => turl)
      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal "fubar", clh.url_for(nil)
      assert_equal "fubar", clh.url_for("")
      assert_equal "fubar", clh.url_for("iso")
      assert_equal "fubar", clh.url_for("ios")
      assert_equal "fubar", clh.url_for("android")
    end

    should "take fallback if default not set" do
      turl = {
        "fallback" => "fubar"
      }
      cl = generate_campaign_link(:target_url => turl)
      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal "fubar", clh.url_for(nil)
      assert_equal "fubar", clh.url_for("")
      assert_equal "fubar", clh.url_for("iso")
      assert_equal "fubar", clh.url_for("ios")
      assert_equal "fubar", clh.url_for("android")
    end

    should "take default before fallback if set" do
      turl = {
        "default"  => "fubar",
        "fallback" => "fallback"
      }
      cl = generate_campaign_link(:target_url => turl)
      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal "fubar", clh.url_for(nil)
      assert_equal "fubar", clh.url_for("")
      assert_equal "fubar", clh.url_for("iso")
      assert_equal "fubar", clh.url_for("ios")
      assert_equal "fubar", clh.url_for("android")
    end

    should "take the platform before fallback" do
      turl = {
        "default"  => "fubar",
        "fallback" => "fallback",
        "ios"      => "ios"
      }
      cl = generate_campaign_link(:target_url => turl)
      clh = ClickHandler.new({:id => cl.id}, OpenStruct.new)
      assert_equal "fubar", clh.url_for(nil)
      assert_equal "fubar", clh.url_for("")
      assert_equal "fubar", clh.url_for("iso")
      assert_equal "ios",   clh.url_for("ios")
      assert_equal "fubar", clh.url_for("android")
    end
  end

  context "compute_platform" do
    should "do this correctly" do
      {
        "iPhone"  => "ios",
        "Android" => "android",
        "Mozilla" => "",
        "Chrome"  => "",
        "Banana"  => "",
        "Windows-RSS-Platform/2.0 (MSIE 9.0; Windows NT 6.1)" => "windows",
        "AmigaVoyager/3.2 (AmigaOS/MC680x0)" => "amigaos",
        ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; " +
         "rv:47.0) Gecko/20100101 Firefox/47.0") => "mac",
        ("Mozilla/5.0 (compatible; MSIE 9.0; AOL 9.7; "+
         "AOLBuild 4343.19; Windows NT 6.1; WOW64; "+
         "Trident/5.0; FunWebProducts)") => "windows",
        ("Mozilla/5.0 (compatible; bingbot/2.0; "+
         "+http://www.bing.com/bingbot.htm)") => "",
        ("Mozilla/5.0 (compatible; DotBot/1.1; http://www.dotnetdotcom.org/"+
         ", crawler@dotnetdotcom.org)") => "",
        ("Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.3pre) "+
         "Gecko/20100403 Lorentz/3.6.3plugin2pre "+
         "(.NET CLR 4.0.20506)") => "windows",
        ("Mozilla/5.0 (X11; FreeBSD i386) AppleWebKit/535.2 "+
         "(KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2") => "freebsd",
        ("Mozilla/5.0 (compatible; BeslistBot; nl; BeslistBot 1.0; "+
         "http://www.beslist.nl/") => ""
      }.each do |user_agent, platform|
        req = OpenStruct.new({ :user_agent => user_agent })
        clh = ClickHandler.new({},req)
        assert_equal platform, clh.compute_platform, "Failed for #{user_agent}"
      end
    end
  end
end
