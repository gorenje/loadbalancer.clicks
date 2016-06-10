get '/click/:id/go' do
  params[:adid] = obtain_adid
  handle_tracking_call
end

get '/favicon.ico' do
  return_one_by_one_pixel
end

get '/apple-*.png' do
  return_one_by_one_pixel
end

get '/robots.txt' do
  "User-agent: *\nDisallow: /\n"
end
