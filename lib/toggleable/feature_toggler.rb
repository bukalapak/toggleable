# frozen_string_literal: true

require 'singleton'
require 'pry'

module Toggleable
  # Toggleable::FeatureToggler provides an instance to manage all toggleable keys.
  class FeatureToggler
    include Singleton

    attr_reader :features

    def initialize
      @features = []
    end

    def register(key)
      features << key
    end

    def available_features
      keys.slice(*features)
    end

    def mass_toggle!(mapping, actor: nil)
      log_changes(mapping, actor) if Toggleable.configuration.logger
      if Toggleable.configuration.namespace
        Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
      else
        Toggleable.configuration.storage.mass_set(mapping)
      end
    end

    private

    def keys
      if Toggleable.configuration.namespace
        Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
      else
        Toggleable.configuration.storage.get_all
      end
    end

    def log_changes(mapping, actor)
      previous_values = available_features
      mapping.each do |key, val|
        next if previous_values[key].to_s == val.to_s
        Toggleable.configuration.logger.log(key: key, value: val, actor: actor)
      end
    end
  end
end
