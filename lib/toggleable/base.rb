# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/numeric/time'

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
      def active?
        return to_bool(toggle_active.to_s) unless toggle_active.nil?

        # Lazily register the key
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

      def toggle_key(value, actor)
        Toggleable.configuration.storage.set(key, value, namespace: Toggleable.configuration.namespace)
        Toggleable.configuration.logger&.log(key: key, value: value, actor: actor)
        Toggleable::FeatureToggler.instance.toggle_key(key, value, actor) if Toggleable.configuration.toggle_client&.safe_constantize&.active?
      end

      def toggle_active
        return @_toggle_active if defined?(@_toggle_active) && !read_expired? && Toggleable.configuration.use_memoization
        @_last_read_at = Time.now.localtime
        @_toggle_active = if Toggleable.configuration.toggle_client&.safe_constantize&.active?
                            Toggleable::FeatureToggler.instance.get_key(key)
                          else
                            Toggleable.configuration.storage.get(key, namespace: Toggleable.configuration.namespace)
                          end
      end

      def read_expired?
        @_last_read_at < Time.now.localtime - Toggleable.configuration.expiration_time
      end

      def to_bool(value)
        return true if value =~ /^(true|t|yes|y|1)$/i
        return false if value.empty? || value =~ /^(false|f|no|n|0)$/i
        raise ArgumentError, "invalid value for Boolean: \"#{value}\""
      end
    end
  end
end
