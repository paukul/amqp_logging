require 'json'


module AMQPLogging
  class MetricsAgent
    DEFAULT_MAX_LINES = 1000
    attr_reader :fields
    attr_accessor :max_lines

    def initialize
      @default_fields = {
        :host => Socket.gethostname.split('.').first,
        :pid => Process.pid,
        :loglines => [],
        :severity => 0
      }
      @max_lines = DEFAULT_MAX_LINES
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
      timestring = AMQPLogging.iso_time_with_microseconds
      self[:severity] = severity if self[:severity] < severity
      if @fields[:loglines].size < @max_lines
        msg = (message || progname).strip
        @fields[:loglines] << [severity, timestring, msg]
        true
      else
        msg = "Loglines truncated to #{@max_lines} lines (MetricsAgent#max_lines)"
        @fields[:loglines][-1] = [Logger::INFO, timestring, msg]
        false
      end
    end

    def wrap_logger(logger)
      agent = self
      logger.instance_eval do
        @agent = agent
        class << self
          include MetricsAgentSupport
        end
      end
      logger
    end

    def dirty?
      @fields != @default_fields
    end

    private

    def reset_fields
      @fields = {
      }.merge!(@default_fields)
      @fields[:loglines] = []
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
