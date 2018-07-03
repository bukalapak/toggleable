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


class SampleLogger < Toggleable::LoggerAbstract
  attr_accessor :logger

  def initialize
    @logger = Logger.new(STDOUT)
  end

  def log(key:, value:, actor:)
    logger.info "Change on #{key} to #{value} by #{actor}"
  end
end

logger = SampleLogger.new

Toggleable.configure do |t|
  t.storage = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
  t.logger = logger
  t.expiration_time = 5.minutes
  t.use_memoization = false
end
