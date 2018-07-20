# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/toggleable/storage'
end

require 'codecov'

SimpleCov.formatter =
  if ENV['CI']
    SimpleCov::Formatter::Codecov
  else
    SimpleCov::Formatter::HTMLFormatter
  end

require 'webmock/rspec'
require 'class_initializer'
