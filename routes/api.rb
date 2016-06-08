post '/api/:version/create' do
  if ENV['API_SECRET_KEY']
    pepper = Digest::SHA1.
      hexdigest(request.env["X-API-SALT"] + params[:campaign_link] +
                ENV['API_SECRET_KEY'])
    halt(404) if params[:pepper] != pepper
  end

  cl = JSON.parse(params[:campaign_link])
  CampaignLink.
    find_or_create_by(:id => cl["id"]).
    update(cl)
  $refresh_cam_lnk_cache.call
  json({ :status => :ok })
end
