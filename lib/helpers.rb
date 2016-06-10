# encoding: UTF-8
module EccrineTracking
  module Helpers
    def obtain_adid
      params[:adid] || params[:idfa] || params[:gadid]
    end

    def handle_tracking_call(redirect = true)
      click_handler = ClickHandler.new(params, request)
      url, respcode = click_handler.handle_call

      if url.blank?
        halt(404)
      elsif !redirect
        [200, ['']]
      elsif respcode
        redirect url, respcode
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
