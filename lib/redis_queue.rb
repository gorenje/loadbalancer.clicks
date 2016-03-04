class RedisQueue

  attr_reader :pool, :key

  def initialize(redis_pool, key = :click_queue)
    @pool = redis_pool
    @key  = key
  end

  def push(click)
    $librato_aggregator.add(
      "#{ENV['LIBRATO_PREFIX']}.click.#{(click[:app_id]||"").gsub(/[^[:alnum:]]/, '')}" => 1
    )

    pool.execute do |redis|
      redis.rpush(key, encode(click))
    end
  rescue EncodingError => e
    $stderr.puts "Encoding issue: #{click.inspect}"
  rescue => e
    $stderr.puts "#{e.message} (#{e.class})"
    $stderr.puts e.backtrace

    type = case e
      when Timeout::Error, Redis::TimeoutError
        :timeout
      when Redis::CannotConnectError
        :connection_error
      when Redis::CommandError
        :command_error
      when CircuitBreaker::CircuitBrokenError
        :circuit_broken
      when RedisPool::NoResourceAvailable
        :no_redis_available
      else
        :unkown
    end

    $librato_queue.add(
      "#{ENV['LIBRATO_PREFIX']}.redisqueue.error" => {
        :source => "#{type}", :value => 1
      }
    )

    NewRelic::Agent.notice_error(e)
  end


  def pop(number_of_elements = 1)
    elements = pool.execute do |redis|
      redis.pipelined do |pipe|
        number_of_elements.times { pipe.lpop(key) }
      end
    end

    elements.compact.map do |element|
      decode(element)
    end
  end

  def size
    pool.execute {|redis| redis.llen(key)}
  end

  def clear!
    pool.execute {|redis| redis.del(key)}
  end

  def show
    pool.execute do |redis|
      redis.lrange(key, 0, 100).map do |clk|
        decode(clk)
      end
    end
  end

private

  def encode(click)
    JSON.dump(click)
  end

  def decode(click)
    JSON.parse(click)
  end
end
