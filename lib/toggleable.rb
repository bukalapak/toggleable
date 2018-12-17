# frozen_string_literal: true

require 'toggleable/version'
require 'toggleable/configuration'
require 'toggleable/storage'
require 'toggleable/instrumentor'
require 'toggleable/logger_abstract'
require 'toggleable/feature_toggler'
require 'toggleable/base'

# Toggleable is a gem for toggling purposes.
module Toggleable
  class << self
    attr_accessor :configuration
  end

  module_function

  def configuration
    @configuration ||= Toggleable::Configuration.new
  end

  def configure
    yield(configuration) if block_given?

    # set default configuration for storage and namespace if none was provided
    configuration.storage         ||= Toggleable::MemoryStore.new
    configuration.namespace       ||= 'toggleable_rspec'
    configuration.expiration_time ||= 5.minutes
  end
end
