require 'bunny'

begin
  require 'active_support/time' # ActiveSupport 3.x
rescue LoadError
  require 'active_support'      # ActiveSupport 2.x
end

module AMQPLogging
  autoload :BufferedJSONLogger, 'amqp_logging/buffered_json_logger'
end

require 'logger'
require 'amqp_logging/logger'
require 'amqp_logging/log_device'
