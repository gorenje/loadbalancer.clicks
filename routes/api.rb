post '/api/:version/create' do
  cl = JSON.parse(params[:campaign_link])
  CampaignLink.
    first_or_create(:id => cl["id"]).
    update(cl)
  $refresh_cam_lnk_cache.call
  json({ :status => :ok })
end
