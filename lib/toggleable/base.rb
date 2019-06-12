# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/numeric/time'
require 'rest-client'

module Toggleable
  # Toggleable::Base provides basic functionality for toggling into a class.
  module Base
    extend ActiveSupport::Concern

    DEFAULT_VALUE = false

    included do
      Toggleable::FeatureToggler.instance.register(key)
    end

    # it will generate these methods into included class.
    module ClassMethods
      def active?(namespace: Toggleable.configuration.namespace)
        toggle_status = toggle_active(namespace)
        return toggle_status.to_s == 'true' unless toggle_status.nil?

        # Lazily register the key
        Toggleable.configuration.storage.set_if_not_exist(key, DEFAULT_VALUE, namespace: Toggleable.configuration.namespace)
        DEFAULT_VALUE
      end

      def activate!(actor: nil, namespace: Toggleable.configuration.namespace)
        toggle_key(true, actor, namespace)
      end

      def deactivate!(actor: nil, namespace: Toggleable.configuration.namespace)
        toggle_key(false, actor, namespace)
      end

      def key
        @key ||= name.underscore
      end

      def description
        name
      end

      # should we encourage proxy classes
      def process
        yield if active?
      end

      private

      def toggle_key(value, actor, namespace)
        Toggleable.configuration.logger&.log(key: key, value: value, actor: actor, namespace: namespace)

        start_time = Time.now
        Toggleable.configuration.storage.set(key, value, namespace: namespace)
        duration = (Time.now - start_time)
        Toggleable.configuration.instrumentor&.latency(duration, 'redis_set', 'ok')

        notify_changes({ key => value.to_s }, actor) if Toggleable.configuration.notify_host && !Toggleable.configuration.blacklisted_notif_key&.include?(key)
      end

      def notify_changes(mapping, actor)
        url = "#{Toggleable.configuration.notify_host}/_internal/toggle-features/bulk-notify"
        payload = { mappings: mapping, user_id: actor.to_s }.to_json
        RestClient::Resource.new(url).post payload, timeout: 2, open_timeout: 1
      rescue StandardError
        nil
      end

      def toggle_active(namespace)
        @_toggle_active ||= {}
        @_last_read_at ||= {}

        return @_toggle_active[namespace] if @_toggle_active.key?(namespace) && !read_expired?(namespace) && Toggleable.configuration.use_memoization
        @_last_read_at[namespace] = Time.now.localtime

        start_time = Time.now
        @_toggle_active[namespace] = Toggleable.configuration.storage.get(key, namespace: namespace)
        duration = (Time.now - start_time)
        Toggleable.configuration.instrumentor&.latency(duration, 'redis_get', 'ok')

        @_toggle_active[namespace]
      rescue StandardError => e
        raise e
      end

      def read_expired?(namespace)
        @_last_read_at[namespace] < Time.now.localtime - Toggleable.configuration.expiration_time
      end
    end
  end
end
