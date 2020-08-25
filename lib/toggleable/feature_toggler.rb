# frozen_string_literal: true

require 'active_support/inflector'
require 'faraday'
require 'json'
require 'net/http/persistent'
require 'singleton'

module Toggleable
  # Toggleable::FeatureToggler provides an instance to manage all toggleable keys.
  class FeatureToggler
    include Singleton

    RETRIABLE_METHODS    = %i[delete get patch post put].freeze
    RETRIABLE_EXCEPTIONS = [Faraday::ConnectionFailed, Faraday::TimeoutError, ::Net::ReadTimeout, 'Timeout::Error'].freeze
    GET_KEY_URL          = '/_internal/toggle-features'
    TOGGLE_KEY_URL       = '/_internal/toggle-features'
    MASS_GET_URL         = '/_internal/toggle-features/collections'
    MASS_SET_URL         = '/_internal/toggle-features/bulk-update'

    attr_reader :features

    def initialize
      @features = []
    end

    def register(key)
      features << key
    end

    def get_key(key, user_id = nil)
      @_toggle_active ||= {}
      @_last_key_read_at ||= {}
      return @_toggle_active[key] if !@_toggle_active[key].nil? && !read_key_expired?(key) && Toggleable.configuration.use_memoization

      Mutant.metric.counter('toggleable_api_attempt', 1, key)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @_last_key_read_at[key] = Time.now.localtime

      begin
        response = connection.get GET_KEY_URL do |req|
          req.options.timeout = 0.2
          req.options.open_timeout = 1
          req.params['feature'] = key
          req.params['user_id'] = user_id.to_i if user_id
        end

        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time)
        Mutant.metric.counter("toggleable_api_success", 1, key: key)
        Mutant.metric.histogram("toggleable_api_latency", duration, key: key)

        result = ::JSON.parse(response.body)
        @_toggle_active[key] = result['data']['status']
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::Error => e
        Mutant.metric.counter("toggleable_api_error", 1, key: key, error_type: e.class.to_s.demodulize)
        Toggleable.configuration.logger.error(message: "GET #{key} TIMEOUT: #{e.message}")
        raise e
      rescue => e
        Mutant.metric.counter("toggleable_api_error", 1, key: key, error_type: e.class.to_s.demodulize)
        raise e
      end
      @_toggle_active[key]
    end

    def toggle_key(key, value, actor: nil)
      payload = { feature: key, status: value, user_id: actor }.to_json

      begin
        connection.put TOGGLE_KEY_URL do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = payload
          req.options.timeout = 0.5
          req.options.open_timeout = 0.75
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::Error => e
        Toggleable.configuration.logger.error(message: "TOGGLE #{key} TIMEOUT: #{e.message}")
        raise e
      end
    end

    def available_features(memoize: Toggleable.configuration.use_memoization)
      return @_memoized_keys if defined?(@_memoized_keys) && !read_all_keys_expired? && memoize

      @_last_read_at = Time.now.localtime
      if Toggleable.configuration.enable_palanca
        toggles = mass_get_palanca
        @_memoized_keys = {}.tap{ |hash| toggles.each{ |toggle| hash[toggle['feature']] = toggle['status'].to_s } }.slice(*features)
      else
        @_memoized_keys = keys.slice(*features)
      end
    end

    def mass_toggle!(mapping, actor:, email:)
      log_changes(mapping, actor) if Toggleable.configuration.logger
      if Toggleable.configuration.enable_palanca
        mass_set_palanca!(mapping, actor: email)
      else
        Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
      end
    end

    def mass_set_palanca!(mapping, actor:)
      payload = { mappings: mapping, user_id: actor }.to_json

      begin
        connection.post MASS_SET_URL do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = payload
          req.options.timeout = 2
          req.options.open_timeout = 1
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::Error => e
        Toggleable.configuration.logger.error(message: "MASS TOGGLE TIMEOUT: #{e.message}")
        raise e
      end
    end

    def mass_get_palanca
      begin
        response = connection.get MASS_GET_URL do |req|
          req.options.timeout = 2
          req.options.open_timeout = 1
        end
        result = ::JSON.parse(response.body)
        toggle_collections = result['data']
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::Error => e
        Toggleable.configuration.logger.error(message: "GET COLLECTIONS TIMEOUT: #{e.message}")
        raise e
      end

      toggle_collections
    end

    private

    def keys
      Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
    end

    def read_all_keys_expired?
      @_last_read_at < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def read_key_expired?(key)
      @_last_key_read_at[key] < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def log_changes(mapping, actor)
      mapping.each do |key, val|
        Toggleable.configuration.logger.log(key: key, value: val, actor: actor)
      end
    end

    def connection
      @connection ||= Faraday.new(url: Toggleable.configuration.palanca_host) do |f|
        f.use Faraday::Response::RaiseError
        f.use Faraday::Request::BasicAuthentication,
              Toggleable.configuration.palanca_user, Toggleable.configuration.palanca_password
        f.request :retry, max: Toggleable.configuration.max_retry.to_i, interval: 0.1, backoff_factor: 2,
                          methods: RETRIABLE_METHODS, exceptions: RETRIABLE_EXCEPTIONS
        f.adapter :net_http_persistent
      end
    end
  end
end
