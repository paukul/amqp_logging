module AMQPLogging
  class MetricsAgent
    attr_reader :fields

    def initialize
      @default_fields = {
        :host => Socket.gethostname.split('.').first,
        :process => Process.pid
      }
      @fields = {
        :loglines => {
          :default => []
        }
      }
    end

    def add_logline(severity, message, progname)
      t = Time.now
      @fields[:loglines][:default] << [severity, t.strftime("%d.%m.%YT%H:%M:%S.#{t.usec}"), message || progname]
    end
    
    def wrap_logger(logger)
      agent = self
      logger.instance_eval do
        @agent = agent
        alias :add_without_proxy :add
        def add_with_proxy(severity, message, progname)
          @agent.add_logline(severity, message, progname)
          add_without_proxy(severity, message, progname)
        end
        alias :add :add_with_proxy
      end
      logger
    end
  end
end