# in der rails app
module AMQPLogging
  module RailsRequestInfoLogging
    # find the right method for this foobar
    def log_processing_for_request_id
      logger.add_field(:page, "#{controller_name}##{action_name}")
      logger.add_field(:page, "#{controller_name}##{action_name}")
      # TODO: ...
      super
    end
  end

  module SimpleFormatter
    def self.call(severity, time, progname, msg)
      msg
    end
  end

  class BufferedJSONLogger < Logger
    attr_reader :buffer
    attr_reader :fields

    def initialize(logdev, *args)
      super
      @default_formatter = SimpleFormatter
      @default_fields = {
        :host => Socket.gethostname.split('.').first,
        :process => Process.pid
      }
      @fields = {}
      @buffer = []
    end

    def add_field(name, value)
      @fields[name] = value
    end

    def add(severity, message = nil, progname = nil, &block)
      severity ||= UNKNOWN
      if severity < @level
        return true
      end
      progname ||= @progname
      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end
      t = Time.now
      formatted_message = format_message(format_severity(severity), t, progname, message)
      @buffer << [severity, t.strftime("%d.%m.%YT%H:%M:%S.#{t.usec}"), formatted_message]
      true
    end
    
    def flush
      @logdev.write(format_json)
      @buffer = []
      @fields = {}
      true
    end

    private
    def format_json
      @default_fields.merge({
        :lines => @buffer,
        :severity => @buffer.map {|l| l[0]}.max
      }).to_json
    end
  end
end