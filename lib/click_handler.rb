require_relative '../lib/helpers.rb'

class ClickHandler

  DefaultCountry = OpenStruct.new(:city_name => nil, :country_code2 => nil)

  attr_reader :adid, :adgroup, :ad, :app_id, :campaign, :click, :ip, :network,
              :partner_data, :platform, :idfa_md5, :idfa_sha1,
              :idfa_comb, :created_at, :device, :app_name

  def initialize(params, request)
    @ip                 = request.ip || '0.0.0.0'
    @device             = ClickHandler.device_from_useragent(request)
    @adid               = params[:adid] ? ClickHandler.pimp_adid_if_broken(params[:adid]) : nil
    @adgroup            = params[:adgroup]
    @ad                 = params[:ad]
    @campaign           = params[:campaign]
    @network            = params[:network]
    @click              = ClickHandler.get_click_param(network, params[:click]||"")
    @partner_data       = params[:partner_data] || params[:cb]
    @platform           = params[:platform] || ClickHandler.platform_from_useragent(request)
    @idfa_md5           = params[:idfa_md5]
    @idfa_sha1          = params[:idfa_sha1]
    @created_at         = DateTime.now
    @idfa_comb          = compose_idfa_comb(@adid, @idfa_md5, @idfa_sha1, params)
    @camlink    = $cam_lnk_cache[params[:id].to_i]

    # private, not for normal consumption.
    @user_agent = request.user_agent
    @referrer   = request.referrer
  end

  def self.platform_from_useragent(request)
    case request.user_agent
      when /iPod;/i, /iPod touch;/i then :iPod
      when /iPad;/i                 then :iPad
      when /iPhone;/i               then :iPhone
      else
        :unknown
    end
  end

  def self.device_from_useragent(request)
    case request.user_agent
      when /(Android|Linux)/i    then :android
      when /(iPhone|iPod|iPad)/i then :apple
      else
        :unknown
    end
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

  def self.locale_from_http_header(request)
    # todo refactor
    # https://github.com/iain/http_accept_language/blob/master/lib/http_accept_language/parser.rb#L18-L34
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.strip
    match = /\A[[:alpha:]]{2},([[:alpha:]]{2}[_-][[:alpha:]]{2})|([[:alpha:]]{2}[_-][[:alpha:]]{2})|([[:alpha:]]{2})/.match(accept_language)
    match ? (match[1]||match[0])[0..4]  : "us"
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
    ($geoip && ip && $geoip.country(ip)) rescue DefaultCountry
  end

  def country_for_ip(ip)
    geoip_country(ip) || DefaultCountry
  end

  def to_click_hash
    {
      :adid               => adid,
      :adgroup            => adgroup,
      :ad                 => ad,
      :campaign           => campaign,
      :network            => network,
      :click              => click,
      :partner_data       => partner_data,
      :platform           => platform,
      :created_at         => created_at,
      :idfa_comb          => idfa_comb,
      :lookup_key         => lookup_key,
      :campaign_link_id   => @camlink.id,
      :attribution_window => created_at..valid_till,
      :country            => country_for_ip(ip).country_code2
    }.reject { |_,v| v.blank? }
  end

  def click_queue
    @click_queue ||= RedisQueue.new($redis_pool)
  end

  def url_for(platform)
    @camlink.target_url[platform] || @camlink.target_url["default"]
  end

  def handle_call
    case device
    when :apple
      click_queue.push(to_click_hash)
      return url_for("ios"), 307
    when :android
      click_queue.push(to_click_hash)
      return url_for("android"), 307
    when :unknown
      click_queue.push(to_click_hash)
      return url_for("default"), 307
    else
      return "",404
    end
  end
end
