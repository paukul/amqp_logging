class AMQPLogging::LogDevice
  RETRY_AFTER = 10.seconds

  attr_reader :exchange, :configuration
  attr_accessor :logger

  def initialize(dev, opts = {})
    @configuration = opts
    @fallback_logdev = dev
  end

  def write(msg)
    begin
      if !@paused || @paused <= RETRY_AFTER.ago
        routing_key = configuration[:routing_key].respond_to?(:call) ? configuration[:routing_key].call(msg).to_s : configuration[:routing_key]
        exchange.publish(msg, :key => routing_key)
      end
    rescue Exception => exception
      reraise_expectation_errors!
      pause_amqp_logging(exception)
    ensure
      @fallback_logdev.write(msg)
    end
  end

  def close
    @fallback_logdev.close
  end

  private
    def pause_amqp_logging(exception)
      @paused = Time.now
      reset_amqp
      logger.errback.call(exception) if logger.errback && logger.errback.respond_to?(:call)
    end

    def reset_amqp
      begin
        bunny.stop if bunny.connected?
      rescue
        # if bunny throws an exception here, its not usable anymore anyway
      ensure
        @exchange = @bunny = nil
      end
    end

    def exchange
      bunny.start unless bunny.connected?
      @exchange ||= bunny.exchange(configuration[:exchange], :type => :topic)
    end

    def bunny
      @bunny ||= Bunny.new(configuration)
      @bunny
    end

    if defined?(Mocha)
      def reraise_expectation_errors! #:nodoc:
        raise if $!.is_a?(Mocha::ExpectationError)
      end
    else
      def reraise_expectation_errors! #:nodoc:
        # noop
      end
    end
end
