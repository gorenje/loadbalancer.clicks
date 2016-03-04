# encoding: UTF-8
module EccrineTracking
  module Helpers

    DefaultCountry = OpenStruct.new(:city_name => nil, :country_code2 => nil)

    def obtain_adid
      adid = params[:adid] || params[:idfa] || params[:gadid]
      ClickParser.valid_adid?(adid) ? adid : nil
    end

    def appstore_from_params
      (!params[:ascc].blank? && params[:ascc]) || nil
    end

    def geoip_country(ip)
      ($geoip && ip && $geoip.country(ip)) rescue DefaultCountry
    end

    def country_for_ip(ip)
      geoip_country(ip) || DefaultCountry
    end

    def obtain_apple_id(app_name)
      app_name = ClickParser.get_apple_app_name(app_name) unless ClickParser.apple_app?(app_name)
      AppleIdLookup[app_name.to_s.downcase] || 'id1009200976'
    end

    def obtain_google_id(app_id, app_name)
      app_name = ClickParser.get_android_app_name(app_name) unless ClickParser.android_app?(app_name)
      GoogleBundleLookup[app_id.to_s.downcase] || GoogleBundleLookup[app_name.to_s.downcase] || 'com.wooga.futurama'
    end

    def handle_tracking_call(redirect = true)
      click_handler = ClickHandler.new(params, request)
      url, code = click_handler.handle_call
      if !redirect
        [200, ['']]
      elsif code
        redirect url, code
      else
        File.read(File.join('public', 'index.html')) #just a file now
      end
    end

    def click_queue
      @click_queue ||= RedisQueue.new($redis_pool)
    end

    def return_one_by_one_pixel
      content_type "image/gif"
      [71,73,70,56,57,97,1,0,1,0,128,1,0,0,0,0,255,255,255,33,249,4,1,0,0,
       1,0,44,0,0,0,0,1,0,1,0,0,2,2,76,1,0,59].pack("C*")
    end
  end
end
