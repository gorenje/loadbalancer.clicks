post '/api/:version/create' do
  halt(404) unless api_secret_match?

  cldata = JSON.parse(params[:campaign_link])
  CampaignLink.
    find_or_create_by(:id => cldata["id"]).
    update(cldata)

  $refresh_cam_lnk_cache.call
  json({ :status => :ok })
end

post '/api/:version/delete' do
  halt(404) unless api_secret_match?

  cldata = JSON.parse(params[:campaign_link])
  CampaignLink.find(cldata["id"]).delete rescue nil

  $refresh_cam_lnk_cache.call
  json({ :status => :ok })
end
