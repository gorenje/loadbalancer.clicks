get '/check' do
  redis_alive = begin
    # this will throw an exception if redis is unreachable
    $redis_pool.with_each do |redis|
      redis.ping
    end
    true
  rescue Exception => e
    $stderr.puts e.message
    $stderr.puts e.backtrace
    false
  end
  redis_alive ? "OK" : "Database unreachable"
end
