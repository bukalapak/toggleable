# encoding: UTF-8
require 'coveralls'
Coveralls.wear!

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter "/spec/"
end

require 'redis'
require 'toggleable'
require 'dotenv'
require 'logger'

Dotenv.load

## Sample implementation for logger
class SampleLogger < Toggleable::LoggerAbstract
  attr_accessor :logger

  def initialize
    @logger = Logger.new(STDOUT)
  end

  def log(key:, value:, actor:)
    logger.info "Change on #{key} to #{value} by #{actor}"
  end
end

## Initialize Toggleable
memory_storage = Toggleable::MemoryStore.new
logger = SampleLogger.new

Toggleable.configure do |t|
  t.logger = logger
  t.expiration_time = 5.minutes
  t.use_memoization = false
end
