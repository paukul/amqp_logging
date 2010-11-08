module AMQPLogging
  module Rails
    class AfterDispatchCallbackHandler
      def self.run(dispatcher)
        env = dispatcher.instance_variable_get(:@env)
        response = env["action_controller.rescue.response"]
        request = env["action_controller.rescue.request"]
        request_headers  = request.headers.dup
        request_headers.each do |k, v|
          case v
          when String, Fixnum, Numeric
          else
            request_headers[k] = "#<#{v.class.name}>"
          end
        end

        ActionController::Base.logger.add_fields({
          :env => RAILS_ENV,
          :response_code    => response.status,
          :request_params   => request.request_parameters,
          :request_headers  => request_headers,
          :response_headers => response.headers
        })
      end
    end
  end
end