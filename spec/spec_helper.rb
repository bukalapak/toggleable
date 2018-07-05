# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start

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
redis_instance = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
redis_storage = Toggleable::RedisStore.new(redis_instance)
logger = SampleLogger.new

Toggleable.configure do |t|
  t.storage = memory_storage
  t.namespace = 'features'
  t.logger = logger
  t.expiration_time = 5.minutes
  t.use_memoization = false
end
