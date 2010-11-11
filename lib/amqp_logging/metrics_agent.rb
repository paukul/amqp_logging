require 'json'


module AMQPLogging
  class MetricsAgent
    attr_reader :fields

    def initialize
      @default_fields = {
        :host => Socket.gethostname.split('.').first,
        :pid => Process.pid,
        :loglines => {
          :default => []
        }
      }
      @logger_types = {}
      reset_fields
    end

    def logger
      @logger || (self.logger = ::Logger.new($stdout))
    end

    def logger=(logger)
      @logger = logger
      @logger.formatter = Proc.new {|_, _, msg, progname| msg || progname}
      @logger
    end

    def flush
      logger.info(@fields.to_json + "\n")
      reset_fields
    end

    def [](fieldname)
      @fields[fieldname]
    end

    def []=(fieldname, value)
      @fields[fieldname] = value
    end

    def add_logline(severity, message, progname, logger)
      t = Time.now
      @fields[:loglines][@logger_types[logger]] << [severity, t.strftime("%Y.%d.%mT%H:%M:%S.#{t.usec}"), message || progname]
    end

    def wrap_logger(logger, type = :default)
      agent = self
      register_logger(logger, type)
      logger.instance_eval do
        @agent = agent
        class << self
          include MetricsAgentSupport
        end
      end
      logger
    end

    private
    def register_logger(logger, type)
      @logger_types[logger] = type
      @fields[:loglines][type] = []
    end

    def reset_fields
      @fields = {
      }.merge!(@default_fields)
      @logger_types.values.each {|logtype| @fields[:loglines][logtype] = []}
    end
    
    module MetricsAgentSupport
      def self.included(base)
        base.class_eval do
          alias :add_without_proxy :add
          alias :add :add_with_proxy
        end
      end

      def agent
        @agent
      end

      def add_with_proxy(severity, message = nil, progname = nil)
        @agent.add_logline(severity, message, progname, self) unless severity < @level
        add_without_proxy(severity, message, progname)
      end
    end
  end
end