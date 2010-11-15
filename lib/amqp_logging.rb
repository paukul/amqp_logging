require 'bunny'

begin
  # ActiveSupport 3.x
  require 'active_support/time'
  require 'active_support/core_ext/hash/slice'
rescue LoadError
  require 'active_support'      # ActiveSupport 2.x
end

module AMQPLogging
  autoload :MetricsAgent, 'amqp_logging/metrics_agent'

  private
  def self.iso_time_with_nanoseconds(t = Time.now)
    t.strftime("%Y-%m-%dT%H:%M:%S.#{t.usec}")
  end
end

require 'logger'
require 'amqp_logging/logger'
require 'amqp_logging/log_device'
