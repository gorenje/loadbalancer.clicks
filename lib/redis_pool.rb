require 'circuit_breaker'

class RedisPool

  BAD_RESOURCE_ERRORS = [
    Redis::CommandError,
    Redis::CannotConnectError,
    Redis::TimeoutError,
    Timeout::Error
  ]

  class NoResourceAvailable < RuntimeError
  end

  class Node
    attr_reader :connection

    def initialize(config)
      @connection = Redis.new(config)
    end

    def execute
      circuit_breaker.execute do
        yield connection
      end
    end

    def available?
      !circuit_breaker.open?
    end

  private
    def circuit_breaker
      @circuit_breaker ||= CircuitBreaker::Basic.new({
        # number of failures before the circuit breaker trips
        failure_threshold: 5,
        # invocation timeout in seconds
        invocation_timeout: 1,
        # a list of timeouts for consecutive failures in seconds. can be used for exponential backoff
        reset_timeouts: [2, 4, 8, 16, 32, 64, 128],
        # a list of errors or exceptions that indicates outtage of service
        errors_handled: [Redis::CommandError, Redis::CannotConnectError, Redis::TimeoutError]
      })
    end
  end

  attr_reader :pool

  def initialize(configs)
    @pool = configs.map do |config|
      Node.new(config)
    end
  end

  def execute
    take do |node|
      node.execute do |con|
        return yield con
      end
    end
  end

  def with_each
    pool.each do |node|
      node.execute do |con|
        yield con
      end
    end
  end

private

  def take
    node    = nil
    skipped = []

    begin
      begin
        index = pool.index {|n| n.available? && !skipped.include?(n)}
        raise NoResourceAvailable.new if index.nil?

        node = pool.delete_at(index)
        return yield node
      ensure
        pool << node if node
      end
    rescue *BAD_RESOURCE_ERRORS => e
      skipped << node

      if skipped.size == pool.size
        raise e
      end

      retry
    end
  end
end
