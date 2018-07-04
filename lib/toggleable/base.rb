# Provides a common interface for toggling features
require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/numeric/time'

module Toggleable
  module Base
    extend ActiveSupport::Concern

    DEFAULT_VALUE = false

    included do
      Toggleable::FeatureToggler.instance.register(key)
    end

    module ClassMethods
      def active?
        return to_bool(toggle_active.to_s) unless toggle_active.nil?

        Toggleable.configuration.storage.set_if_not_exist(key, DEFAULT_VALUE, namespace: Toggleable.configuration.namespace)
        DEFAULT_VALUE
      end

      def activate!(actor: nil)
        toggle_key(true, actor)
      end

      def deactivate!(actor: nil)
        toggle_key(false, actor)
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

      def toggle_key(value, actor)
        Toggleable.configuration.logger&.log(key: key, value: value, actor: actor)

        if Toggleable.configuration.namespace
          Toggleable.configuration.storage.set(key, value, namespace: Toggleable.configuration.namespace)
        else
          Toggleable.configuration.storage.set(key, value)
        end
      end

      def toggle_active
        return @_toggle_active if defined?(@_toggle_active) && !read_expired? && Toggleable.configuration.use_memoization
        @_last_read_at = Time.now.localtime
        @_toggle_active = Toggleable.configuration.namespace ? Toggleable.configuration.storage.get(key, namespace: Toggleable.configuration.namespace) : Toggleable.configuration.storage.get(key)
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
