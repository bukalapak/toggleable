require 'singleton'

module Toggleable
  class FeatureToggler
    include Singleton

    NAMESPACE = 'features'.freeze

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

    def mass_toggle!(mapping)
      Toggleable.configuration.redis.hmset(NAMESPACE, mapping.flatten)
    end

    private

    def keys
      Toggleable.configuration.redis.hgetall(NAMESPACE)
    end
  end
end
