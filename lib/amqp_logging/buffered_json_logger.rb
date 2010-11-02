require 'json'


# in der rails app
module AMQPLogging
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
    
    def add_fields(extra_fields)
      @fields.merge!(extra_fields)
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
      formatted_message = format_message(format_severity(severity), t, progname, message).strip
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
        :lines => @buffer.reverse,
        :severity => @buffer.map {|l| l[0]}.max
      }).merge(@fields).to_json + "\n"
    end

  end
end