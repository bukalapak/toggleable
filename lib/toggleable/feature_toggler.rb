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
      $redis_host.hmset(NAMESPACE, mapping.flatten)
    end

    private

    def keys
      $redis_host.hgetall(NAMESPACE)
    end
  end
end
