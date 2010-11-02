require 'amqp_logging'
require 'amqp_logging/buffered_json_logger/rails/after_dispatch_callback_handler'


ActionController::Dispatcher.after_dispatch do |dispatcher|
  AMQPLogging::Rails::AfterDispatchCallbackHandler.run(dispatcher)
end

class ActionController::Base
  def log_processing_for_request_id_with_json_logger_preparation
    logger.add_field     :page, "#{self.class.name}\##{action_name}"
    log_processing_for_request_id_without_json_logger_preparation
  end
  alias_method_chain :log_processing_for_request_id, :json_logger_preparation
end