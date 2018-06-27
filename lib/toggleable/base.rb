# Provides a common interface for toggling features
require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/object/blank'

module Toggleable
  module Base
    extend ActiveSupport::Concern

    NAMESPACE = Toggleable::FeatureToggler::NAMESPACE
    DEFAULT_VALUE = false

    included do
      Toggleable::FeatureToggler.instance.register(key)
    end

    module ClassMethods
      def active?
        return to_bool(toggle_active.to_s) unless toggle_active.nil?

        Toggleable.configuration.redis.hsetnx(NAMESPACE, key, DEFAULT_VALUE)
        DEFAULT_VALUE
      end

      def activate!
        Toggleable.configuration.redis.hset(NAMESPACE, key, true)
      end

      def deactivate!
        Toggleable.configuration.redis.hset(NAMESPACE, key, false)
      end

      def key
        @_key ||= name.underscore
      end

      def description
        name
      end

      # should we encourage proxy classes
      def process
        yield if active?
      end

      private

      def toggle_active
        return @_toggle_active if defined?(@_toggle_active) && !read_expired? && !Toggleable.configuration.development_mode
        @_last_read_at = Time.now.localtime
        @_toggle_active = Toggleable.configuration.redis.hget(NAMESPACE, key)
      end

      def read_expired?
        @_last_read_at < Time.now.localtime - Toggleable.configuration.expiration_time
      end

      def to_bool(value)
        return true if value =~ (/^(true|t|yes|y|1)$/i)
        return false if value.empty? || value =~ (/^(false|f|no|n|0)$/i)
        raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
      end
    end
  end
end
