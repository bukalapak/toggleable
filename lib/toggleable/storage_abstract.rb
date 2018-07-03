module Toggleable
  class StorageAbstract
    ## the storage you provide must implement these methods

    def get(_namespace, _key)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def get_all(_namespace)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def set(_namespace, _key, _value)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def set_if_not_exist(_namespace, _key, _value)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def mass_set(_namespace, *attrs)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end
  end
end
