# Provides a common interface for toggling features
require 'active_support/core_ext/numeric/time'

module Toggleable
  module Base
    extend ActiveSupport::Concern

    NAMESPACE = Toggleable::FeatureToggler::NAMESPACE
    DEFAULT_VALUE = false
    EXPIRED_INTERVAL = 5.minutes

    included do
      Toggleable::FeatureToggler.instance.register(key)
    end

    module ClassMethods
      def active?
        return toggle_active.to_bool unless toggle_active.nil?

        $redis_host.hsetnx(NAMESPACE, key, DEFAULT_VALUE)
        DEFAULT_VALUE
      end

      def activate!
        $redis_host.hset(NAMESPACE, key, true)
      end

      def deactivate!
        $redis_host.hset(NAMESPACE, key, false)
      end

      def key
        @_key ||= name.snakecase
      end

      def description
        name
      end

      # should we encourage proxy classes, heh heh
      def process
        yield if active?
      end

      private

      def toggle_active
        return @_toggle_active if defined?(@_toggle_active) && !read_expired? && !Rails.env.test?
        @_last_read_at = Time.now.localtime
        @_toggle_active = $redis_host.hget(NAMESPACE, key)
      end

      def read_expired?
        @_last_read_at < Time.now.localtime - EXPIRED_INTERVAL
      end

      def snakecase
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr('-', '_').
        gsub(/\s/, '_').
        gsub(/__+/, '_').
        downcase
      end
    end
  end
end
