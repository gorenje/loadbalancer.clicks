# called by the index.html after redirecting the user.
get '/' do
  params[:adid] = obtain_adid
  click_parser = ClickParser.new(params, request)
  case click_parser.device
    when :apple
      click_parser.change_to_apple_app_name!
    when :android
      click_parser.change_to_google_app_name!
  end
  click_queue.push(click_parser.to_hash)

  return_one_by_one_pixel
end

get '/noredirect/?' do
  params[:adid] = obtain_adid
  handle_tracking_call(:redirect => false)
end

get '/track/?' do
  params[:adid] = obtain_adid
  handle_tracking_call
end

post '/track/?' do
  params[:adid] = obtain_adid
  handle_tracking_call
end

get '/adid/?' do
  params[:adid] = obtain_adid
  handle_tracking_call
end

get '/details' do
  redirect "https://play.google.com/store/apps/details?#{request.query_string}"
end

get '/favicon.ico' do
  return_one_by_one_pixel
end

get '/apple-*.png' do
  return_one_by_one_pixel
end
