require File.dirname(__FILE__) + '/test_helper.rb'

module AMQPLogging
  class TheBufferedJSONLoggerTest < Test::Unit::TestCase
    def setup
      @output = StringIO.new
      @logger = BufferedJSONLogger.new(@output)
    end
    
    test "should have all the convenience log methods of a regular logger" do
      ::Logger::Severity.constants.map(&:downcase).each do |logmethod|
        assert_nothing_raised do
          @logger.send(logmethod, "foo")
        end
      end
    end

    test "should not write the logs immediately" do
      assert_equal "", @output.string
      @logger.debug "foo"
      assert_equal "", @output.string
    end
    
    test "should write to the log when flush is called eventually" do
      assert_equal "", @output.string
      @logger.debug "foo"
      @logger.flush
      assert_match /foo/, @output.string
    end
    
    test "should empty the buffer when flush is called" do
      @logger.debug "foo"
      @logger.flush
      assert_equal [], @logger.buffer
    end
  end
  
  class BufferedLoggerJSONOutputTest < Test::Unit::TestCase
    def setup
      @output = StringIO.new
      @logger = BufferedJSONLogger.new(@output)
      @logger.debug "foo"
      @logger.warn  "bar"
      @logger.info  "baz"
      @logger.flush
      @json = JSON.parse(@output.string)
    end

    test "should have the loglines in a array called lines" do
      assert @json["lines"].instance_of?(Array)
      assert_equal 3, @json["lines"].size
    end

    test "should have each logline with severity, a timestamp and the message" do
      severity, timestamp, message = @json["lines"][2]
      assert_equal Logger::DEBUG, severity
      assert_nothing_raised { Time.parse(timestamp) }
      assert_equal "foo", message
    end
    
    test "should have a field with the highest severity" do
      assert_equal Logger::WARN, @json["severity"]
    end
    
    test "should have a field with the process id" do
      assert_equal Process.pid, @json["process"]
    end
    
    test "should have a field with the hostname" do
      assert_equal Socket.gethostname.split('.').first, @json["host"]
    end
  end
end