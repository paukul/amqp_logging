require 'amqp_logging'
require 'amqp_logging/metrics_agent/rails/after_dispatch_callback_handler'

ActionController::Dispatcher.after_dispatch do |dispatcher|
  AMQPLogging::Rails::AfterDispatchCallbackHandler.run(dispatcher)
end

class ActionController::Base
  def log_processing_for_request_id_with_metrics_agent
    logger.agent[:page] = "#{self.class.name}\##{action_name}"
    t = Time.now
    logger.agent[:started_at] = t.strftime("%Y-%d-%mT%H:%M:%S.#{t.usec}")
    log_processing_for_request_id_without_metrics_agent
  end
  alias_method_chain :log_processing_for_request_id, :metrics_agent
end