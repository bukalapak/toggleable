require 'singleton'

module Toggleable
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
      log_changes(mapping, actor) if Toggleable::configuration.logger
      Toggleable.configuration.storage.mass_set(Toggleable.configuration.namespace, mapping.flatten)
    end

    private

    def keys
      Toggleable.configuration.storage.get_all(Toggleable.configuration.namespace)
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
