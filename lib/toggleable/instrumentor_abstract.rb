# frozen_string_literal: true

module Toggleable
  # Toggleable::InstrumentorAbstract describes the interface class for instrumentor.
  class InstrumentorAbstract
    ## the instrumentor you provide must implement these methods

    def latency(_duration, _action, _status)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    private

    def method_name
      caller_locations(1, 1)[0].label
    end
  end
end
