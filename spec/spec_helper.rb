# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'

SimpleCov.formatter =
  if ENV['CI']
    SimpleCov::Formatter::Codecov
  else
    SimpleCov::Formatter::HTMLFormatter
  end


SimpleCov.start do
  add_filter '/spec/'
end

require 'class_initializer'
