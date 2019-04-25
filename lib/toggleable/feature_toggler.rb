# frozen_string_literal: false

require 'singleton'
require 'rest-client'

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

    def get_key(key)
      @_toggle_active ||= {}
      @_last_key_read_at ||= {}
      toggle_status = toggle_active(key)
      return toggle_status unless toggle_status.nil?

      # Lazily register the key
      Toggleable.configuration.storage.set_if_not_exist(key, DEFAULT_VALUE, namespace: Toggleable.configuration.namespace)
      DEFAULT_VALUE
    end

    def toggle_key(key, value, actor)
      prev = Toggleable.configuration.storage.get(key, namespace: Toggleable.configuration.namespace)

      Toggleable.configuration.logger&.log(key: key, value: value, actor: actor)
      Toggleable.configuration.storage.set(key, value, namespace: Toggleable.configuration.namespace)
      notify_changes({ key => value.to_s }, actor) if should_notify?(key, prev, value)
    end

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
      available_features.sort_by{ |k, _v| k }.to_h
    end

    def mass_toggle!(mapping, actor: nil)
      log_changes(mapping, actor) if Toggleable.configuration.logger

      return if mapping.empty?

      start_time = Time.now
      Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_mass_set', 'ok')

      mapping.transform_values!(&:to_s)
      notify_changes(mapping, actor) if Toggleable.configuration.notify_host
    end

    private

    def keys
      start_time = Time.now
      keys = Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_mass_get', 'ok')

      keys
    end

    def toggle_active(key)
      return @_toggle_active[key] if Toggleable.configuration.use_memoization && @_toggle_active.key?(key) && !read_key_expired?(key)

      @_last_key_read_at[key] = Time.now.localtime

      start_time = Time.now
      @_toggle_active[key] = Toggleable.configuration.storage.get(key, namespace: Toggleable.configuration.namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_get', 'ok')

      @_toggle_active[key]
    rescue StandardError
      false
    end

    def memoized_keys
      return @_memoized_keys if defined?(@_memoized_keys) && !read_all_keys_expired?
      @_last_read_at = Time.now.localtime

      start_time = Time.now
      @_memoized_keys = Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
      duration = (Time.now - start_time)
      Toggleable.configuration.instrumentor&.latency(duration, 'redis_mass_get', 'ok')

      @_memoized_keys
    end

    def read_all_keys_expired?
      @_last_read_at < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def read_key_expired?(key)
      @_last_key_read_at[key] < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def log_changes(mapping, actor)
      previous_mapping = available_features(memoize: false)
      mapping.each do |key, val|
        previous_mapping[key] != val.to_s ? Toggleable.configuration.logger.log(key: key, value: val, actor: actor) : mapping.delete(key)
      end
    end

    def should_notify?(key, prev, value)
      Toggleable.configuration.notify_host && !Toggleable.configuration.blacklisted_notif_key&.include?(key) && (prev != value.to_s)
    end

    def notify_changes(mapping, actor)
      url = "#{Toggleable.configuration.notify_host}/_internal/toggle-features/bulk-notify"
      payload = { mappings: mapping, user_id: actor.to_s }.to_json
      RestClient::Resource.new(url).post payload, timeout: 2, open_timeout: 1
    rescue StandardError
      nil
    end
  end
end
