require_relative '../lib/helpers.rb'

class ClickHandler

  MinuteFractionOfDay = 1/1440.to_f

  attr_reader :adid, :click, :ip, :partner_data, :platform, :idfa_md5,
              :idfa_sha1, :idfa_comb, :created_at, :app_name, :user_agent,
              :camlink

  def initialize(params, request)
    @created_at   = DateTime.now
    @camlink      = obtain_campaign_link(params[:id].to_i)
    @ip           = request.ip || '0.0.0.0'
    @adid         = ClickHandler.uuidify_adid(params[:adid])
    @click        = params[:click]
    @partner_data = params[:partner_data] || params[:cb]
    @idfa_md5     = params[:idfa_md5]
    @idfa_sha1    = params[:idfa_sha1]
    @idfa_comb    = compose_idfa_comb(@adid, @idfa_md5, @idfa_sha1, params)
    @user_agent   = request.user_agent
    @platform     = compute_platform
    @reqparams    = compose_reqparams(params)
  end

  def self.uuidify_adid(adid)
    return nil if adid.nil?
    if adid =~ /^([a-f0-9]{8})([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{12})$/i
      "#{$1}-#{$2}-#{$3}-#{$4}-#{$5}"
    else
      adid
    end.upcase
  end

  def self.report(message, params)
    $stderr.puts "VALIDATION: #{message.to_s.dup.split('_').map {|x| x.capitalize }.join(' ')}: #{params.inspect}"
    $librato_queue.add(
      "#{ENV['LIBRATO_PREFIX']}.#{message}" => {
        :source => params[:network] || 'unknown',
        :value => 1
      }
    )
  end

  def self.valid_idfa_comb(idfa, idfa_md5, idfa_sha1)
    if idfa =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i
      idfa.upcase
    elsif idfa_md5 =~ /[a-f0-9]{32}/i
      idfa_md5.downcase
    elsif idfa_sha1 =~ /[a-f0-9]{40}/i
      idfa_sha1.downcase
    end
  end

  def click_queue
    @click_queue ||= RedisQueue.new($redis_pool)
  end

  def compute_platform
    DeviceDetector.new(@user_agent).os_name.to_s.downcase
  end

  def obtain_campaign_link(id)
    $cam_lnk_cache[id] || $refresh_cam_lnk_cache.call[id]
  end

  def has_idfa_comb?
    !@idfa_comb.nil?
  end

  def url_for(plform)
    @camlink.target_url[plform] || @camlink.target_url["default"] ||
      @camlink.target_url["fallback"]
  end

  def compose_idfa_comb(idfa, idfa_md5, idfa_sha1, params)
    result = nil
    unless idfa.blank? && idfa_md5.blank? && idfa_sha1.blank?
      result = ClickHandler.valid_idfa_comb(idfa, idfa_md5, idfa_sha1)
      ClickHandler.report('invalid_idfa', params) if result.nil?
    end
    result
  end

  def compose_reqparams(params)
    # original parameters but remove everything that we use or send already
    {}.merge(params).tap do |p|
      ["id", "adid", :adid, "idfa", "gadid", "click", "captures", "idfa_md5",
       "idfa_sha1", "partner_data"].each { |key| p.delete(key) }
    end
  end

  def lookup_key
    if has_idfa_comb?
      Digest::MD5.hexdigest("#{idfa_comb}".downcase)
    else
      Digest::MD5.hexdigest("#{ip}.#{platform}".downcase)
    end
  end

  def valid_till
    @created_at + (if has_idfa_comb?
                     @camlink.attribution_window_idfa
                   else
                     @camlink.attribution_window_fingerprint
                   end * MinuteFractionOfDay)
  end

  def click_to_kafka_string(extras = {})
    paramsuri = Addressable::URI.new
    paramsuri.query_values = @reqparams

    uri = Addressable::URI.new
    uri.query_values = {
      ## for reference
      :adid             => adid,
      :network          => @camlink.network,
      :adgroup          => @camlink.adgroup,
      :ad               => @camlink.ad,
      :campaign         => @camlink.campaign,
      :created_at       => created_at.to_s,
      ## for attribution of clicks to installs, the following:
      :click            => click,
      :partner_data     => partner_data,
      :idfa_comb        => idfa_comb,
      :lookup_key       => lookup_key,
      :attr_window_from => created_at.to_s,
      :attr_window_till => valid_till.to_s,
      ## For statistics and consumer sanity
      :campaign_link_id => @camlink.id,
      :user_id          => @camlink.user_id,
      :reqparams        => paramsuri.query
    }.merge(extras)

    "%s %i clicks /t/click %s %s" % [ip, Time.now.to_i, uri.query, user_agent]
  end

  def handle_call
    url = url_for(platform)

    url = if url.blank?
            ENV['NOT_FOUND_URL'].blank? ? nil : ENV['NOT_FOUND_URL']
          else
            url
          end

    click_queue.push(click_to_kafka_string(:redirect_url => url))
    url.blank? ? ["",404] : [url,307]
  end
end
