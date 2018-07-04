module Toggleable
  class StorageAbstract
    ## the storage you provide must implement these methods
    ## namespace parameter is optional, only if you provide namespace configuration

    def get(_key, _namespace: nil)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def get_all(_namespace: nil)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def set(_key, _value, _namespace: nil)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def mass_set(*attrs, _namespace: nil)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end
  end
end
