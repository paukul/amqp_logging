require 'rubygems'
require 'bundler'
Bundler.require

logger = Logger.new($stdout)
agent  = AMQPLogging::MetricsAgent.new
agent.wrap_logger(logger)
agent.logger = Logger.new("agent.log")

logger.debug  "1. foo"
logger.info   "1. bar"
logger.warn   "1. baz"

agent.flush

logger.debug  "2. foo"
logger.info   "2. bar"
logger.warn   "2. baz"

agent.flush

