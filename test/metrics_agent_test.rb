require File.dirname(__FILE__) + '/test_helper.rb'

module AMQPLogging
  # class MetricsAgentTest
  # end

  class LoggingProxyTest < Test::Unit::TestCase
    def setup
      @agent = MetricsAgent.new
      @logger = ::Logger.new('/dev/null')
      @proxy = @agent.wrap_logger(@logger)
    end

    test "should return a logger proxy that quaks like a regular logger" do
      @logger.expects(:debug)
      @proxy.debug "foobar"
    end

    test "should register every logline on the agent" do
      @agent.expects(:add_logline).with(0, nil, "foobar")
      @proxy.debug("foobar")
    end

    test "should store the loglines" do
      assert_equal 0, @agent.fields[:loglines][:default].size
      @proxy.debug("foobar")
      assert_equal 1, @agent.fields[:loglines][:default].size
    end
  end
end
