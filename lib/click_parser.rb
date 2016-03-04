require_relative '../lib/helpers.rb'

class ClickParser
  def initialize(params, request)
    @ip                 = request.ip || '0.0.0.0'
    @device             = ClickParser.device_from_useragent(request)
    @adid               = params[:adid] ? ClickParser.pimp_adid_if_broken(params[:adid]) : nil
    @adgroup            = params[:adgroup]
    @ad                 = params[:ad]
    @campaign           = params[:campaign]
    @network            = params[:network]
    @click              = ClickParser.get_click_param(network, params[:click]||"")
    @partner_data       = params[:partner_data] || params[:cb]
    @platform           = params[:platform] || ClickParser.platform_from_useragent(request)
    @idfa_md5           = params[:idfa_md5]
    @idfa_sha1          = params[:idfa_sha1]
    @created_at         = DateTime.now
    @idfa_comb          = compose_idfa_comb(@adid, @idfa_md5, @idfa_sha1, params)
    # private, not for normal consumption.
    @user_agent = request.user_agent
    @referrer = request.referrer
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

  def compose_idfa_comb(idfa, idfa_md5, idfa_sha1, params)
    result = nil
    unless idfa.blank? && idfa_md5.blank? && idfa_sha1.blank?
      result = ClickParser.valid_idfa_comb(idfa, idfa_md5, idfa_sha1)
      if result.nil? && !InvalidIDFAWhitelist.include?(params[:network].to_s)
        ClickParser.report('invalid_idfa', params)
      end
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

  def self.report(message, params)
    $stderr.puts "VALIDATION: #{message.to_s.dup.split('_').map {|x| x.capitalize }.join(' ')}: #{params.inspect}"
    $librato_queue.add(
      "#{ENV['LIBRATO_PREFIX']}.#{message}" => {
        :source => params[:network] || 'unknown',
        :value => 1
      }
    )
  end

  def to_hash
    {
      :ip           => ip,
      :adid         => adid,
      :adgroup      => adgroup,
      :ad           => ad,
      :app_id       => app_id,
      :campaign     => campaign,
      :network      => network,
      :click        => click,
      :partner_data => partner_data,
      :platform     => platform,
      :created_at   => created_at,
      :idfa_comb    => idfa_comb,
      :lookup_key   => lookup_key,
      :attribution_window   => created_at..valid_till,
    }.reject { |_,v| v.blank? }
  end
end
