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

  def initialize(options=DEFAULT_OPTIONS)
    options = DEFAULT_OPTIONS.merge(options)
    super(nil)
    @logdev = AMQPLogging::LogDevice.new(options)
    @logdev.logger = self
  end
end