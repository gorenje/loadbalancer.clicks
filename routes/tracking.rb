get '/track/:id/go' do
  # hack to refresh the campaign cache, expensive to do this on every
  # request but updating global variables is stupid.
  $refresh_cam_lnk_cache.call
  params[:adid] = obtain_adid
  handle_tracking_call
end

get '/favicon.ico' do
  return_one_by_one_pixel
end

get '/apple-*.png' do
  return_one_by_one_pixel
end
