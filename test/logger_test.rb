require File.dirname(__FILE__) + '/test_helper.rb'


class TheAMQPLoggerTest < Test::Unit::TestCase
  def setup
    @io = StringIO.new
  end

  test "should be instanciated with an amqp configuration hash" do
    config = { :queue => "testqueue", :exchange => "testexchange", :host => "testhost", :shift_age => 4, :shift_size => 1338, :routing_key => "foobar", :exchange_durable => true, :exchange_auto_delete => false, :exchange_type => :topic }
    AMQPLogging::LogDevice.expects(:new).with(config).returns(stub_everything)

    logger = AMQPLogging::Logger.new(config)
  end

  test "should pause AMQP logging if exceptions during logging occure" do
    # in case you ask why not just using mocha expectations here: the rescue in the tested code also rescues the mocha exception
    # this fake exchange object increases a counter everytime publish is executed so we can check the number of executions
    class TestExchange; attr_reader :counter; def publish(*args); @counter ||= 0; @counter += 1; raise 'Foo'; end; end
    logger = AMQPLogging::Logger.new
    exchange = TestExchange.new
    AMQPLogging::LogDevice.any_instance.stubs(:exchange).returns(exchange)
    AMQPLogging::LogDevice.any_instance.stubs(:bunny).returns(stub_everything("bunny stub"))
    2.times { logger.debug "This will raise" }

    assert_equal 1, exchange.counter
  end
  
  test "should call the logger errback with the exception that occured if one is set" do
    class FooBarException < Exception; end
    @called = false

    errback = lambda {|exception| begin raise exception; rescue FooBarException; @called = true; end}
    raising_exchange = mock("mocked exchange")
    raising_exchange.expects(:publish).raises(FooBarException)
    AMQPLogging::LogDevice.any_instance.stubs(:exchange).returns(raising_exchange)
    logger = AMQPLogging::Logger.new
    logger.errback = errback

    assert_nothing_raised do
      logger.debug("this will raise")
    end
    assert @called
  end

  test "should reset the bunny and exchange instance if a exception occures" do
    raising_exchange = mock("mocked exchange")
    raising_exchange.expects(:publish).raises("FFFFFFFFUUUUUUUUUU")
    AMQPLogging::LogDevice.any_instance.stubs(:exchange).returns(raising_exchange)
    logger = AMQPLogging::Logger.new

    AMQPLogging::LogDevice.any_instance.expects(:reset_amqp)
    logger.debug("This will raise and send a notification")
  end

end

class TheLogDeviceTest < Test::Unit::TestCase
  test "should initialize the AMQP components correctly" do
    config = { :queue => "testqueue", :exchange => "testexchange", :host => "testhost", :shift_age => 4, :shift_size => 1338 }
    bunny_stub = stub_everything("bunny_stub")
    Bunny.expects(:new).with(:host => "testhost").returns(bunny_stub)
    bunny_stub.expects(:exchange).with(config[:exchange], :durable     => true,
                                                          :auto_delete => false,
                                                          :type        => :topic).returns(stub("exchange stub", :publish => true))

    logger = AMQPLogging::Logger.new(config)
    logger.debug("foobar")
  end

  test "should publish the messages with the default routing key" do
    message = "some stuff to log"
    exchange = mock()
    exchange.expects(:publish).with(anything, :key => "a_routing_key")
    AMQPLogging::LogDevice.any_instance.stubs(:exchange).returns(exchange)
    AMQPLogging::Logger.new(:routing_key => "a_routing_key").debug(message)
  end

  test "should take a proc argument which gets the logline passed to generate the routing key" do
    key_generator = lambda {|msg| !!(msg =~ /a message/) }
    exchange = mock()
    exchange.expects(:publish).with(anything, :key => "true")
    AMQPLogging::LogDevice.any_instance.stubs(:exchange).returns(exchange)
    AMQPLogging::Logger.new(:routing_key => key_generator).debug("a message")
  end
end

