# frozen_string_literal: true

require 'singleton'

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

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
      available_features.slice(*features)
    end

    def mass_toggle!(mapping, actor: nil)
      log_changes(mapping, actor) if Toggleable.configuration.logger
      if Toggleable.configuration.namespace
        Toggleable.configuration.storage.mass_set(mapping.flatten, namespace: Toggleable.configuration.namespace)
      else
        Toggleable.configuration.storage.mass_set(mapping.flatten)
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
