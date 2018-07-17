# frozen_string_literal: true

require 'singleton'
require 'rest-client'
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
      response = ''
      attempt = 1
      url = "#{ENV['PALANCA_HOST']}/_internal/toggle_features?key=#{key}"
      resource = RestClient::Resource.new(url, ENV['PALANCA_BASIC_USER'], ENV['PALANCA_BASIC_PASSWORD'])

      while response.empty?
        begin
          response = resource.get timeout: 5, open_timeout: 1
          response = ::JSON.parse(response)
          result = response['data']['status']
        rescue StandardError => _e
          if attempt >= MAX_ATTEMPT
            Toggleable.configuration.logger.error(message: "GET #{key} TIMEOUT")
            result = false
            break
          end
          attempt += 1
        end
      end
      result
    end

    def available_features(memoize: Toggleable.configuration.use_memoization)
      available_features = memoize ? memoized_keys : keys
      available_features.slice(*features)
    end

    def mass_toggle!(mapping, actor: nil)
      Toggleable.configuration.storage.mass_set(mapping, namespace: Toggleable.configuration.namespace)
      return if Toggleable.configuration.toggle_fallback&.active?

      response = ''
      attempt = 1
      url = "#{ENV['PALANCA_HOST']}/_internal/toggle_features/collections"
      payload = { mappings: mapping, actor: actor }.to_json
      @resource ||= RestClient::Resource.new(url, ENV['PALANCA_BASIC_USER'], ENV['PALANCA_BASIC_PASSWORD'])

      while response.empty?
        begin
          response = @resource.put payload, timeout: 5, open_timeout: 1
        rescue StandardError => e
          if attempt >= MAX_ATTEMPT
            Toggleable.configuration.logger.error(message: 'MASS TOGGLE TIMEOUT')
            raise e
          end
          attempt += 1
        end
      end
      log_changes(mapping, actor) if Toggleable.configuration.logger
    end

    private

    def keys
      Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
    end

    def memoized_keys
      return @_memoized_keys if defined?(@_memoized_keys) && !read_expired?
      @_last_read_at = Time.now.localtime
      @_memoized_keys = Toggleable.configuration.storage.get_all(namespace: Toggleable.configuration.namespace)
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
