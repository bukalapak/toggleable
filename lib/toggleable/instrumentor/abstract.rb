# frozen_string_literal: true

module Toggleable
  # Toggleable::InstrumentorAbstract describes the interface class for instrumentor.
  class InstrumentorAbstract
    ## the storage you provide must implement these methods
    ## namespace parameter is optional, only if you provide namespace configuration

    def instrument_latency(_duration, _action, _status)
      raise NotImplementedError, "You must implement #{method_name}"
    end
  end
end
