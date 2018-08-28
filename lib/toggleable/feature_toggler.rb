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
      Toggleable.configuration.logger&.log(key: key, value: value, actor: actor)
      Toggleable.configuration.storage.set(key, value, namespace: Toggleable.configuration.namespace)
    end

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
      available_features.sort_by{ |k, _v| k }.to_h
    end

    def mass_toggle!(mapping, actor: nil)
      log_changes(mapping, actor) if Toggleable.configuration.logger
      Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
    end

    private

    def keys
      Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
    end

    def toggle_active(key)
      return @_toggle_active[key] if Toggleable.configuration.use_memoization && @_toggle_active.key?(key) && !read_key_expired?(key)

      @_last_key_read_at[key] = Time.now.localtime
      @_toggle_active[key] = Toggleable.configuration.storage.get(key, namespace: Toggleable.configuration.namespace)
    rescue StandardError
      false
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
      @_last_key_read_at[key] < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def log_changes(mapping, actor)
      toggles = ''
      values = ''
      mapping.each do |key, val|
        Toggleable.configuration.logger.log(key: key, value: val, actor: actor)
        toggles.concat("#{key},")
        values.concat("#{val},")
      end

      notify_changes(toggles[0...-1], values[0...-1]) if Toggleable.configuration.notify_host
    end

    def notify_changes(toggles, values)
      url = "#{Toggleable.configuration.notify_host}/notify_toggle?keys=#{toggles}&values=#{values}"
      RestClient::Resource.new(url).get timeout: 2, open_timeout: 1
    rescue StandardError
      nil
    end
  end
end
