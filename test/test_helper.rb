$:.unshift(File.expand_path('../../lib', __FILE__))
require 'rubygems'
require 'test/unit'
require 'mocha'
require 'active_support/testing/declarative'

begin
  require 'redgreen' unless ENV['TM_FILENAME']
rescue LoadError
end

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
end

require 'amqp_logging'