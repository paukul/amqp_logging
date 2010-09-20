require 'bunny'

begin
  require 'active_support/time' # ActiveSupport 3.x
rescue LoadError
  require 'active_support'      # ActiveSupport 2.x
end

module AMQPLogging
end

require 'amqp_logging/logger'
require 'amqp_logging/log_device'
