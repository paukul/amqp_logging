require 'amqp_logging'
require 'amqp_logging/metrics_agent/rails/after_dispatch_callback_handler'

class ActionController::Base
  attr_writer :metrics_agent

  def metrics_agent
    @metrics_agent ||= AMQPLogging::MetricsAgent.new
  end
end

ActionController::Dispatcher.after_dispatch do |dispatcher|
  AMQPLogging::Rails::AfterDispatchCallbackHandler.run(dispatcher)
end

class ActionController::Base
  def log_processing_for_request_id_with_metrics_agent
    metrics_agent[:page] = "#{self.class.name}\##{action_name}"
    log_processing_for_request_id_without_metrics_agent
  end
  alias_method_chain :log_processing_for_request_id, :metrics_agent
end