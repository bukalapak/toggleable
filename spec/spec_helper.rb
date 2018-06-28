# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'
require 'redis'
require 'toggleable'
require 'dotenv'

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start

Dotenv.load

Toggleable.configure do |t|
  t.storage = Redis.new(host: ENV['HOST'], port: ENV['PORT'])
  t.expiration_time = 5.minutes
  t.use_memoization = false
end
