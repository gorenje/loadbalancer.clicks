post '/api/:version/create' do
  cl = JSON.parse(params[:campaign_link])
  CampaignLink.
    find_or_create_by(:id => cl["id"]).
    update(cl)
  $refresh_cam_lnk_cache.call
  json({ :status => :ok })
end
