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
        Toggleable::FeatureToggler.instance.get_key(key)
      end

      def activate!(actor: nil, email: nil)
        toggle_key(true, actor, email)
      end

      def deactivate!(actor: nil, email: nil)
        toggle_key(false, actor, email)
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

      def toggle_key(value, actor, email)
        Toggleable.configuration.logger&.log(key: key, value: value, actor: actor)
        Toggleable::FeatureToggler.instance.toggle_key(key, value, actor: (email || actor)) if Toggleable.configuration.enable_palanca
      end
    end
  end
end
