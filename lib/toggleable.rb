# Provides a common interface for toggling features
require "toggleable/version"
require "toggleable/feature_toggler"
require "toggleable/base"
require "toggleable/schedule"
require "toggleable/configuration"

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
  end
end
