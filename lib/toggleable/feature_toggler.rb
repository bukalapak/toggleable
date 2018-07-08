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

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
      available_features.slice(*features)
    end

    def mass_toggle!(mapping, actor: nil)
      log_changes(mapping, actor) if Toggleable::configuration.logger
      Toggleable.configuration.storage.hmset(NAMESPACE, mapping.flatten)
    end

    private

    def keys
      Toggleable.configuration.storage.hgetall(NAMESPACE)
    end

    def memoized_keys
      return @_memoized_keys if defined?(@_memoized_keys) && !read_expired?
      @_last_read_at = Time.now.localtime
      @_memoized_keys = Toggleable.configuration.storage.hgetall(NAMESPACE)
    end

    def read_expired?
      @_last_read_at < Time.now.localtime - Toggleable.configuration.expiration_time
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
