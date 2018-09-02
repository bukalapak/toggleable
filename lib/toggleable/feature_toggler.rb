# frozen_string_literal: true

require 'singleton'
require 'rest-client'
require 'active_support/inflector'
require 'json'

module Toggleable
  # Toggleable::FeatureToggler provides an instance to manage all toggleable keys.
  class FeatureToggler
    include Singleton

    MAX_ATTEMPT = 3

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
      return @_toggle_active[key] if !@_toggle_active[key].nil? && !read_key_expired?(key)

      @_last_key_read_at[key] = Time.now.localtime
      response = ''
      attempt = 1
      url = "#{Toggleable.configuration.palanca_host}/_internal/toggle-features?feature=#{key}"
      resource = RestClient::Resource.new(url, Toggleable.configuration.palanca_user, Toggleable.configuration.palanca_password)

      while response.empty?
        begin
          response = resource.get timeout: 2, open_timeout: 1
          response = ::JSON.parse(response)
          @_toggle_active[key] = response['data']['status']
        rescue StandardError => e
          if attempt >= MAX_ATTEMPT
            Toggleable.configuration.logger.error(message: "GET #{key} TIMEOUT")
            raise e
          end
          attempt += 1
        end
      end
      @_toggle_active[key]
    end

    def toggle_key(key, value, actor: nil)
      response = ''
      attempt = 1
      url = "#{Toggleable.configuration.palanca_host}/_internal/toggle-features"
      payload = { feature: key, status: value, user_id: actor }.to_json
      resource = RestClient::Resource.new(url, Toggleable.configuration.palanca_user, Toggleable.configuration.palanca_password)

      while response.empty?
        begin
          response = resource.put payload, timeout: 2, open_timeout: 1
        rescue StandardError => e
          if attempt >= MAX_ATTEMPT
            Toggleable.configuration.logger.error(message: "TOGGLE #{key} TIMEOUT")
            raise e
          end
          attempt += 1
        end
      end
    end

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
      available_features.slice(*features)
    end

    def mass_toggle!(mapping, actor:, email:)
      log_changes(mapping, actor) if Toggleable.configuration.logger
      Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
      mass_set_palanca!(mapping, actor: email) if Toggleable.configuration.enable_palanca
    end

    def mass_set_palanca!(mapping, actor:)
      response = ''
      attempt = 1
      url = "#{Toggleable.configuration.palanca_host}/_internal/toggle-features/bulk-update"
      payload = { mappings: mapping, user_id: actor }.to_json
      resource = RestClient::Resource.new(url, Toggleable.configuration.palanca_user, Toggleable.configuration.palanca_password)
      while response.empty?
        begin
          response = resource.post payload, timeout: 2, open_timeout: 1
        rescue StandardError => e
          if attempt >= MAX_ATTEMPT
            Toggleable.configuration.logger.error(message: 'MASS TOGGLE TIMEOUT')
            raise e
          end
          attempt += 1
        end
      end
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
      @_last_key_read_at[key] < Time.now.localtime - Toggleable.configuration.expiration_time
    end

    def log_changes(mapping, actor)
      mapping.each do |key, val|
        Toggleable.configuration.logger.log(key: key, value: val, actor: actor)
      end
    end
  end
end
