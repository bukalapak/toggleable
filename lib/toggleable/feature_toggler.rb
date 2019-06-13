# frozen_string_literal: false

require 'singleton'

module Toggleable
  # Toggleable::FeatureToggler provides an instance to manage all toggleable keys.
  class FeatureToggler
    include Singleton

    DEFAULT_VALUE = false

    attr_reader :features

    def initialize
      @features = []
    end

    def register(key)
      features << key
    end

    def get_key(key, namespace: Toggleable.configuration.namespace)
      @_toggle_active ||= {}
      @_last_key_read_at ||= {}
      @_toggle_active[namespace] ||= {}
      @_last_key_read_at[namespace] ||= {}
      toggle_status = toggle_active(key, namespace)
      return toggle_status unless toggle_status.nil?

      # Lazily register the key
      Toggleable.configuration.storage.set_if_not_exist(key, DEFAULT_VALUE, namespace: namespace)
      DEFAULT_VALUE
    end

    def create_key(key, value, actor, namespace: Toggleable.configuration.namespace)
      success = Toggleable.configuration.storage.set_if_not_exist(key, value, namespace: namespace)
      return unless success

      Toggleable.configuration.logger&.log(key: key, value: value, actor: actor, namespace: namespace)
      Toggleable.configuration.notifier&.notify({ key => value.to_s }, actor, namespace)

      success
    end

    def toggle_key(key, value, actor, namespace: Toggleable.configuration.namespace)
      prev = Toggleable.configuration.storage.get(key, namespace: namespace)

      Toggleable.configuration.logger&.log(key: key, value: value, actor: actor, namespace: namespace)
      Toggleable.configuration.storage.set(key, value, namespace: namespace)
      Toggleable.configuration.notifier&.notify({ key => value.to_s }, actor, namespace) if should_notify?(key, prev, value)
    end

    def available_features(memoize: Toggleable.configuration.use_memoization, namespace: Toggleable.configuration.namespace)
      available_features = memoize ? memoized_keys(namespace) : keys(namespace)
      available_features.sort_by{ |k, _v| k }.to_h
    end

    def mass_toggle!(mapping, namespace: Toggleable.configuration.namespace, actor: nil)
      log_changes(mapping, actor, namespace) if Toggleable.configuration.logger

      return if mapping.empty?

      start_time = Time.now
      Toggleable.configuration.storage.mass_set(mapping, namespace: namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_mass_set', 'ok')

      mapping.transform_values!(&:to_s)
      Toggleable.configuration.notifier&.notify(mapping, actor, namespace)
    end

    private

    def keys(namespace)
      start_time = Time.now
      keys = Toggleable.configuration.storage.get_all(namespace: namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_mass_get', 'ok')

      keys
    end

    def toggle_active(key, namespace)
      return @_toggle_active[namespace][key] if Toggleable.configuration.use_memoization && @_toggle_active[namespace].key?(key) && !read_key_expired?(key, namespace)

      @_last_key_read_at[namespace][key] = Time.now.localtime

      start_time = Time.now
      @_toggle_active[namespace][key] = Toggleable.configuration.storage.get(key, namespace: namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_get', 'ok')

      @_toggle_active[namespace][key]
    rescue StandardError
      false
    end

    def memoized_keys(namespace)
      @_memoized_keys ||= {}
      @_last_read_at ||= {}

      return @_memoized_keys[namespace] if @_memoized_keys.key?(namespace) && !read_all_keys_expired?(namespace)

      @_last_read_at[namespace] = Time.now.localtime

      start_time = Time.now
      @_memoized_keys[namespace] = Toggleable.configuration.storage.get_all(namespace: namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_mass_get', 'ok')

      @_memoized_keys[namespace]
    end

    def read_all_keys_expired?(namespace)
      @_last_read_at[namespace] < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def read_key_expired?(key, namespace)
      @_last_key_read_at[namespace][key] < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def log_changes(mapping, actor, namespace)
      previous_mapping = available_features(memoize: false, namespace: namespace)
      mapping.each do |key, val|
        previous_mapping[key] != val.to_s ? Toggleable.configuration.logger.log(key: key, value: val, actor: actor, namespace: namespace) : mapping.delete(key)
      end
    end

    def should_notify?(key, prev, value)
      !Toggleable.configuration.blacklisted_notif_key&.include?(key) && (prev != value.to_s)
    end
  end
end
