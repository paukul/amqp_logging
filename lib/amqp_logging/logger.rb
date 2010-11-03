class AMQPLogging::Logger < ::Logger
  DEFAULT_OPTIONS = {
    :shift_age    => 0,
    :shift_size   => 1048576,
    :host         => "localhost",
    :exchange     => "logging_exchange",
    :queue        => "logging_queue",
    :routing_key  => "logs",
    :exchange_durable     => true,
    :exchange_auto_delete => false,
    :exchange_type        => :topic,
  }

  attr_accessor :extra_attributes
  attr_accessor :errback

  def initialize(logdev, *args)
    options = args.first.is_a?(Hash) ? DEFAULT_OPTIONS.merge(args.first) : DEFAULT_OPTIONS
    super(logdev, options[:shift_age], options[:shift_size])
    @logdev = AMQPLogging::LogDevice.new(@logdev, options)
    @logdev.logger = self
  end
  
  def fallback_logdev=(io)
    @logdev.fallback_logdev = io
  end
  alias :logdev= :fallback_logdev=
end