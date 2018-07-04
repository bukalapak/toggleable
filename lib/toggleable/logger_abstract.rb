# frozen_string_literal: true

module Toggleable
  # Toggleable::LoggerAbstract describes the interface class for logger.
  class LoggerAbstract
    # the redis you provide must implement these methods

    def log(_key:, _value:, _actor:)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    private

    def method_name
      caller_locations(1, 1)[0].label
    end
  end
end
