# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'
require 'redis'
require 'toggleable'
require 'dotenv'
require 'logger'

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start

Dotenv.load

## Sample implementation for storage
class SampleStorage < Toggleable::StorageAbstract
  attr_accessor :storage

  def initialize
    @storage = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
  end

  def get(namespace, key)
    storage.hget(namespace, key)
  end

  def get_all(namespace)
    storage.hgetall(namespace)
  end

  def set(namespace, key, value)
    storage.hset(namespace, key, value)
  end

  def set_if_not_exist(namespace, key, value)
    storage.hsetnx(namespace, key, value)
  end

  def mass_set(namespace, *attrs)
    storage.hmset(namespace, *attrs)
  end
end

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
storage = SampleStorage.new
logger = SampleLogger.new

Toggleable.configure do |t|
  t.storage = storage
  t.namespace = 'features'
  t.logger = logger
  t.expiration_time = 5.minutes
  t.use_memoization = false
end
