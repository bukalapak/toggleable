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

    def get_key(key)
      @_toggle_active ||= {}
      return @_toggle_active[key] if !@_toggle_active[key].nil? && !read_key_expired?(key)

      @_last_key_read_at[key] = Time.now.localtime
      @_toggle_active[key] = Toggleable.configuration.storage.get(key, namespace: Toggleable.configuration.namespace)
    end

    def toggle_key(key, value, actor)
      Toggleable.configuration.logger&.log(key: key, value: value, actor: actor)
      Toggleable.configuration.storage.set(key, value, namespace: Toggleable.configuration.namespace)
    end

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
    end

    def mass_toggle!(mapping, actor: nil)
      log_changes(mapping, actor) if Toggleable.configuration.logger
      Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
    end

    private

    def keys
      Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
    end

    def memoized_keys
      return @_memoized_keys if defined?(@_memoized_keys) && !read_all_keys_expired?
      @_last_read_at = Time.now.localtime
      @_memoized_keys = Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
    end

    def read_all_keys_expired?
      @_last_read_at < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def read_key_expired?(key)
      @_last_key_read_at ||= {}
      @_last_key_read_at[key] < Time.now.localtime - Toggleable.configuration.expiration_time
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
