# frozen_string_literal: true

module Toggleable
  # Toggleable::NotifierAbstract describes the interface class for notifier.
  class NotifierAbstract
    ## the notifier you provide must implement these methods

    def notify(_mapping, _actor, _namespace)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    private

    def method_name
      caller_locations(1, 1)[0].label
    end
  end
end
