# frozen_string_literal: true

module Toggleable
  # Toggleable::StorageAbstract describes the interface class for storage.
  class StorageAbstract
    ## the storage you provide must implement these methods
    ## namespace parameter is optional, only if you provide namespace configuration

    def get(_key, _namespace: nil)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    def get_all(_namespace: nil)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    def set(_key, _value, _namespace: nil)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    def set_if_not_exist(_key, _value, namespace: nil)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    def mass_set(*_attrs, namespace: nil)
      raise NotImplementedError, "You must implement #{method_name}"
    end

    private

    def method_name
      caller_locations(1, 1)[0].label
    end
  end
end
