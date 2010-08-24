require 'bunny'
require 'active_support'
require 'active_support/time'

module AMQPLogging

  DEFAULT_OPTIONS = {
    :shift_age    => 0,
    :shift_size   => 1048576,
    :host         => "localhost",
    :exchange     => "logging_exchange",
    :queue        => "logging_queue",
    :routing_key  => "logs"
  }

  RETRY_AFTER = 10.seconds

  class Logger < ::Logger
    attr_accessor :extra_attributes
    attr_accessor :errback

    def initialize(logdev, *args)
      options = args.first.is_a?(Hash) ? DEFAULT_OPTIONS.merge(args.first) : DEFAULT_OPTIONS
      super(logdev, options[:shift_age], options[:shift_size])
      @logdev = AMQPLogDevice.new(@logdev, options)
      @logdev.logger = self
    end
  end

  class AMQPLogDevice
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
        @bunny ||= Bunny.new(:host => configuration[:host])
        @bunny
      end
  end

end

