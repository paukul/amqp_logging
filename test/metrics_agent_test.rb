require File.dirname(__FILE__) + '/test_helper.rb'


module AMQPLogging
  class MetricsAgentTest < Test::Unit::TestCase
    def setup
      @agent = MetricsAgent.new
      @out = StringIO.new
      @agent.logger = ::Logger.new(@out)
    end

    test "should record the process id" do
      assert_equal Process.pid, @agent[:pid]
    end

    test "should record the hostname" do
      assert_equal Socket.gethostname.split('.').first, @agent[:host]
    end

    test "should have convenience methods for accessing the fields" do
      @agent[:foo] = :bar
      assert_equal :bar, @agent[:foo]
      assert_equal @agent[:foo], @agent[:foo]
    end

    test "should send the collected data as json when flushed" do
      @agent.flush
      json = JSON.parse(@out.string)
      assert_equal Process.pid, json["pid"]
    end

    test "should reset the collected data when flushed" do
      @agent[:foo] = :bar
      @agent.flush
      assert_equal nil, @agent[:foo]
    end

    test "should keep track if the agents data is dirty" do
      assert !@agent.dirty?

      @agent[:foo] = :bar
      assert @agent.dirty?
    end

    test "flushing should reset dirty status" do
      @agent[:foo] = :bar
      assert @agent.dirty?

      @agent.flush
      assert !@agent.dirty?
    end
  end

  class LoggingProxyTest < Test::Unit::TestCase
    def setup
      @agent = MetricsAgent.new
      @agent.logger = ::Logger.new('/dev/null')
      @logger = ::Logger.new('/dev/null')
      @proxy = @agent.wrap_logger(@logger)
    end

    test "should return a logger proxy that quaks like a regular logger" do
      @logger.expects(:debug)
      @proxy.debug "foobar"
    end

    test "should register every logline on the agent" do
      @agent.expects(:add_logline).with(0, nil, "foobar", @logger)
      @proxy.debug("foobar")
    end

    test "should take the loglevel of the logger into account" do
      @logger.level = ::Logger::INFO
      no_lines_before_logging = @agent[:loglines][:default].size
      @logger.debug "something"
      assert_equal no_lines_before_logging, @agent[:loglines][:default].size
    end

    test "should store the loglines" do
      assert_equal 0, @agent[:loglines][:default].size
      @proxy.debug("foobar")
      assert_equal 1, @agent[:loglines][:default].size
    end

    test "should store each logline with severity, a timestamp and the message" do
      some_logline = "asdf0asdf"
      @proxy.debug "foo"
      @proxy.warn  "bar"
      @proxy.info  some_logline
      severity, timestamp, message = @agent[:loglines][:default][2]
      assert_equal Logger::INFO, severity
      assert_nothing_raised { Time.parse(timestamp) }
      assert_equal some_logline, message
    end

    test "should keep track of the highest log severity" do
      @proxy.debug "foo"
      assert_equal Logger::DEBUG, @agent[:severity]
      @proxy.warn  "bar"
      assert_equal Logger::WARN, @agent[:severity]
      @proxy.debug "baz"
      assert_equal Logger::WARN, @agent[:severity]
    end

    test "should allow to register multiple loggers with different types" do
      other_logger = ::Logger.new('/dev/null')
      @agent.wrap_logger(other_logger, :sql)
      other_logger.info("some fancy stuff here")
      assert_equal 1, @agent[:loglines][:sql].size
    end

    test "should reset the collected loglines when flushed" do
      @proxy.debug "foo"
      @agent.flush
      assert_equal [], @agent[:loglines][:default]
    end

    test "should keep loglines fields for the registered loggers after flushing" do
      other_logger = ::Logger.new('/dev/null')
      @agent.wrap_logger(other_logger, :sql)
      other_logger.info "foo"
      @agent.flush

      assert_equal [], @agent[:loglines][:sql]
    end

    test "should remove leading and trailing newlines from the stored loglines" do
      @proxy.debug "\n\nfoo\n\n"
      assert_equal "foo", @agent[:loglines][:default][-1][2]
    end

    test "should have a limit of loglines per logger after which they will get ignored" do
      @agent.max_lines_per_logger = 2
      @logger.debug "foo"
      @logger.debug "bar"
      no_lines_before = @agent[:loglines][:default].size
      @logger.debug "baz"
      assert_equal no_lines_before, @agent[:loglines][:default].size
    end

    test "should replace the last logged line with a truncation note if the limit of loglines is exceeded" do
      @agent.max_lines_per_logger = 1
      @logger.debug "foo"
      assert_equal "foo", @agent[:loglines][:default].last[2]
      @logger.debug "bar"
      assert_match /truncated/, @agent[:loglines][:default].last[2]
    end
  end
end
