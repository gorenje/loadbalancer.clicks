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
    @base_data = {
      :campaign     => "test",
      :adgroup      => "adgroup",
      :ad           => "ad",
      :network      => "test",
      :user_id      => "1"
    }
    @adid = '44566636-6BC5-48DE-B4AE-7DF9DF06B356'
    @lk_key = "eb2e4ebe9bf98f8c92efc5f2cb468b18"
  end

  context "basic" do
    should "do correct redirct based on platform - adid" do
      { "ios"     => "iPhone",
        "android" => "Android",
        "default" => "asdasdasd"
      }.each do |platform, user_agent|
        assert_msg = "Failed for #{platform}"
        cl = generate_campaign_link(@base_data)
        unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

        get("/click/#{cl.id}/go", { :adid => @adid },
            { 'HTTP_USER_AGENT' => user_agent})

        assert_redirect_to(platform, assert_msg)

        click_details, params = pop_click
        assert_equal user_agent, click_details.last, assert_msg

        assert_click_params(params, unchanged_cl_data.
                            merge("lookup_key"=> @lk_key,
                                  "idfa_comb" => @adid),assert_msg)
      end
    end

    should "do correct redirct based on platform - idfa" do
      { "ios"     => "iPhone",
        "android" => "Android",
        "default" => "asdasdasd"
      }.each do |platform, user_agent|
        assert_msg = "Failed for #{platform}"
        cl = generate_campaign_link(@base_data)
        unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

        get("/click/#{cl.id}/go", {:idfa => @adid},
            {'HTTP_USER_AGENT' => user_agent})

        assert_redirect_to(platform, assert_msg)

        click_details, params = pop_click
        assert_equal user_agent, click_details.last, assert_msg

        assert_click_params(params, unchanged_cl_data.
                            merge("lookup_key"=> @lk_key,
                                  "idfa_comb" => @adid),assert_msg)
      end
    end

    should "do correct redirct based on platform - gadid" do
      { "ios"     => "iPhone",
        "android" => "Android",
        "default" => "asdasdasd"
      }.each do |platform, user_agent|
        assert_msg = "Failed for #{platform}"
        cl = generate_campaign_link(@base_data)
        unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

        get("/click/#{cl.id}/go", { :gadid => @adid },
            { 'HTTP_USER_AGENT' => user_agent})

        assert_redirect_to(platform, assert_msg)

        click_details, params = pop_click
        assert_equal user_agent, click_details.last, assert_msg

        assert_click_params(params, unchanged_cl_data.
                            merge("lookup_key"=> @lk_key,
                                  "idfa_comb" => @adid),assert_msg)
      end
    end

    should "support broken adids" do
      cl = generate_campaign_link(@base_data)
      unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

      get("/click/#{cl.id}/go", { :gadid => @adid.gsub(/-/,'').downcase },
          { 'HTTP_USER_AGENT' => "iPhone"})

      assert_redirect_to "ios"

      click_details, params = pop_click
      assert_equal "iPhone", click_details.last

      assert_click_params(params, unchanged_cl_data.
                          merge("lookup_key"=> @lk_key,
                                "idfa_comb" => @adid))
    end

    should "handle bad adids - lookup key based on ip & platform" do
      cl = generate_campaign_link(@base_data)
      unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

      silence_is_golden do
        get("/click/#{cl.id}/go", { :idfa => "fubar" },
            {'HTTP_USER_AGENT' => "iPhone"})
      end

      lk_key = Digest::MD5.hexdigest("127.0.0.1.ios".downcase)
      assert_redirect_to "ios"

      click_details, params = pop_click
      assert_equal "iPhone", click_details.last

      assert_click_params(params, unchanged_cl_data.
                          merge("lookup_key"   => lk_key,
                                "idfa_comb"    => nil))
    end

    should "support md5 idfa" do
      cl = generate_campaign_link(@base_data)
      unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

      idfa_md5 = "eb2e4ebe9bf98f8c92efc5f2cb468b18"
      get("/click/#{cl.id}/go", {:idfa_md5 => idfa_md5},
          {'HTTP_USER_AGENT' => "iPhone"})

      lk_key = Digest::MD5.hexdigest(idfa_md5.downcase)
      assert_redirect_to "ios"

      click_details, params = pop_click
      assert_equal "iPhone", click_details.last

      assert_click_params(params, unchanged_cl_data.
                          merge("lookup_key"   => lk_key,
                                "idfa_comb"    => idfa_md5))
    end

    should "support sha1 idfa" do
      cl = generate_campaign_link(@base_data)
      unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

      idfa_sha1 = "eb2e4ebe9bf98f8c92efc5f2cb468b18eb2eeb2e"
      get("/click/#{cl.id}/go", {:idfa_sha1 => idfa_sha1},
          {'HTTP_USER_AGENT' => "iPhone"})

      lk_key = Digest::MD5.hexdigest(idfa_sha1.downcase)
      assert_redirect_to "ios"

      click_details, params = pop_click
      assert_equal "iPhone", click_details.last

      assert_click_params(params, unchanged_cl_data.
                          merge("lookup_key"   => lk_key,
                                "idfa_comb"    => idfa_sha1))
    end

    should "pass through all parameters on the request" do
      cl = generate_campaign_link(@base_data)
      unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

      idfa_sha1 = "eb2e4ebe9bf98f8c92efc5f2cb468b18eb2eeb2e"
      get("/click/#{cl.id}/go", {:idfa_sha1 => idfa_sha1, :fubar => :snafu},
          {'HTTP_USER_AGENT' => "iPhone"})

      lk_key = Digest::MD5.hexdigest(idfa_sha1.downcase)
      assert_redirect_to "ios"

      click_details, params = pop_click
      assert_equal "iPhone", click_details.last

      assert_click_params(params, unchanged_cl_data.
                          merge("lookup_key"   => lk_key,
                                "idfa_comb"    => idfa_sha1))
      reqparams = CGI.parse(params["reqparams"].first)
      assert_equal "snafu", reqparams["fubar"].first
    end
  end

  context "error handling" do
    should "handle exception" do
      add_to_env('ERROR_PAGE_URL' => "http://example.org/exception") do
        get("/click/-1/go", {:idfa_sha1 => ""},
            {'HTTP_USER_AGENT' => "iPhone"})

        assert_redirect_to "exception"
        assert_equal 0, @queue.size
      end
    end

    should "generate 404 if no url is found" do
      cl = generate_campaign_link(@base_data.merge(:target_url => {}))
      unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

      get("/click/#{cl.id}/go", { :idfa => @adid },
          {'HTTP_USER_AGENT' => "iPhone"})

      assert last_response.not_found?

      click_details, params = pop_click
      assert_equal "iPhone", click_details.last

      assert_click_params(params, unchanged_cl_data.
                          merge("lookup_key"   => @lk_key,
                                "idfa_comb"    => @adid,
                                "redirect_url" => nil))
    end

    should "support a NOT_FOUND_URL if no url is found in campaign link" do
      add_to_env('NOT_FOUND_URL' => "http://example.org/notfound") do
        cl = generate_campaign_link(@base_data.merge(:target_url => {}))
        unchanged_cl_data = {"campaign_link_id" => cl.id.to_s}.merge(@base_data)

        get("/click/#{cl.id}/go", { :idfa => @adid },
            {'HTTP_USER_AGENT' => "iPhone"})

        assert_redirect_to "notfound"

        click_details, params = pop_click
        assert_equal "iPhone", click_details.last

        assert_click_params(params, unchanged_cl_data.
                            merge("lookup_key"   => @lk_key,
                                  "idfa_comb"    => @adid,
                                  "redirect_url" => "http://example.org/notfound"))
      end
    end
  end
end
