class AMQPLogging::Logger < ::Logger
  DEFAULT_OPTIONS = {
    :shift_age    => 0,
    :shift_size   => 1048576,
    :host         => "localhost",
    :exchange     => "logging_exchange",
    :queue        => "logging_queue",
    :routing_key  => "logs"
  }

  attr_accessor :extra_attributes
  attr_accessor :errback

  def initialize(logdev, *args)
    options = args.first.is_a?(Hash) ? DEFAULT_OPTIONS.merge(args.first) : DEFAULT_OPTIONS
    super(logdev, options[:shift_age], options[:shift_size])
    @logdev = AMQPLogging::LogDevice.new(@logdev, options)
    @logdev.logger = self
  end
end