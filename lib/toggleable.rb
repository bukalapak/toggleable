# frozen_string_literal: true

require 'toggleable/version'
require 'toggleable/configuration'
require 'toggleable/storage'
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
    yield(configuration)

    # set default storage using memory store if no storage was provided
    Toggleable.configuration.storage ||= Toggleable::MemoryStore.new
  end
end
