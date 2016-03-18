require_relative '../lib/helpers.rb'

class ClickHandler

  DefaultCountry = OpenStruct.new(:iso_code => nil)

  attr_reader :adid, :adgroup, :ad, :campaign, :click, :ip, :network,
              :partner_data, :platform, :idfa_md5, :idfa_sha1,
              :idfa_comb, :created_at, :device, :app_name, :device_detector

  def initialize(params, request)
    @device_detector = DeviceDetector.new(request.user_agent)
    @camlink         = $cam_lnk_cache[params[:id].to_i]

    @ip           = request.ip || '0.0.0.0'
    @device       = @device_detector.device_type.to_s.downcase
    @adid         = params[:adid] ? ClickHandler.pimp_adid_if_broken(params[:adid]) : nil
    @adgroup      = @camlink.adgroup
    @ad           = @camlink.ad
    @campaign     = @camlink.campaign
    @network      = @camlink.network
    @click        = ClickHandler.get_click_param(network, params[:click]||"")
    @partner_data = params[:partner_data] || params[:cb]
    @platform     = @device_detector.os_name.to_s.downcase
    @idfa_md5     = params[:idfa_md5]
    @idfa_sha1    = params[:idfa_sha1]
    @created_at   = DateTime.now
    @idfa_comb    = compose_idfa_comb(@adid, @idfa_md5, @idfa_sha1, params)

    # private, not for normal consumption.
    @user_agent = request.user_agent
    @referrer   = request.referrer
  end

  def self.pimp_adid_if_broken(adid)
    if adid =~ /^([a-f0-9]{8})([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{12})$/i
      "#{$1}-#{$2}-#{$3}-#{$4}-#{$5}"
    else
      adid
    end.upcase
  end

  def self.get_click_param(network, param)
    click = param[0..254]
    $librato_queue.add(
      "#{ENV['LIBRATO_PREFIX']}.invalid_click_param" => {
        :source => network,
        :value  => 1
      }
    ) if click != param
    click
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

  def self.valid_adid?(adid)
    !valid_adid(adid).nil?
  end

  def self.valid_adid(adid)
    (!adid.blank? && !(adid =~ /^[0-]+$/) && adid) || nil
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

  def compose_idfa_comb(idfa, idfa_md5, idfa_sha1, params)
    result = nil
    unless idfa.blank? && idfa_md5.blank? && idfa_sha1.blank?
      result = ClickHandler.valid_idfa_comb(idfa, idfa_md5, idfa_sha1)
      ClickHandler.report('invalid_idfa', params) if result.nil?
    end
    result
  end

  def has_idfa_comb?
    !@idfa_comb.nil?
  end

  def lookup_key
    if has_idfa_comb?
      Digest::MD5.hexdigest("#{idfa_comb}".downcase)
    else
      Digest::MD5.hexdigest("#{ip}.#{platform}".downcase)
    end
  end

  def valid_till
    if has_idfa_comb?
      @created_at + (@camlink.attribution_window_idfa * (1/3600.to_f))
    else
      @created_at + (@camlink.attribution_window_fingerprint * (1/3600.to_f))
    end
  end

  def geoip_country(ip)
    ($geoip && ip && $geoip.lookup(ip).country) rescue DefaultCountry
  end

  def country_for_ip(ip)
    geoip_country(ip) || DefaultCountry
  end

  def to_click_hash(extras = {})
    {
      ## General information about the click parameters:
      :network            => network,
      :adid               => adid,
      :adgroup            => adgroup,
      :ad                 => ad,
      :campaign           => campaign,
      :created_at         => created_at,
      ## for attribution of clicks to installs, the following:
      :click              => click,
      :partner_data       => partner_data,
      :idfa_comb          => idfa_comb,
      :lookup_key         => lookup_key,
      :attribution_window => created_at..valid_till,
      ## For fraud detection, include the following:
      :campaign_link_id   => @camlink.id,
      :country            => country_for_ip(ip).iso_code,
      :platform           => platform,
      :device_name        => device_detector.device_name,
      :device_type        => device_detector.device_type,
      :bot_name           => device_detector.bot_name,
    }.merge(extras).reject { |_,v| v.blank? }
  end

  def click_queue
    @click_queue ||= RedisQueue.new($redis_pool)
  end

  def url_for(plform)
    @camlink.target_url[plform] || @camlink.target_url["default"]
  end

  def handle_call
    url = url_for(platform)

    click_queue.push(to_click_hash(:redirect_url => url))

    url.blank? ? ["",404] : [url, 307]
  end
end
