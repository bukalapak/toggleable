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

  def error(message:)
    logger.error message
  end
end

## Initialize Toggleable
memory_storage = Toggleable::MemoryStore.new
logger = SampleLogger.new

Toggleable.configure do |t|
  t.logger = logger
  t.palanca_host = 'http://localhost:8027'
  t.use_memoization = false
  t.enable_palanca = true
end
