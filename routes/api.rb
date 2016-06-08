post '/api/:version/create' do
  unless ENV['API_SECRET_KEY'].blank?
    pepper = Digest::SHA1.
      hexdigest(request.env["HTTP_X_API_SALT"] + params[:campaign_link] +
                ENV['API_SECRET_KEY']) rescue ""
    halt(404) if params[:pepper] != pepper
  end

  cl = JSON.parse(params[:campaign_link])
  CampaignLink.
    find_or_create_by(:id => cl["id"]).
    update(cl)
  $refresh_cam_lnk_cache.call
  json({ :status => :ok })
end
