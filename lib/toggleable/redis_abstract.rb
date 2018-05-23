module Toggleable
  class RedisAbstract
    ## the redis you provide must implement these methods

    def get(_key)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def set(_key, _value, _options = {})
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def hget(_key, _field)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def hgetall(_key)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def hset(_key, _field, _value)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def hsetnx(_key, _field, _value)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def hmset(_key, *attrs)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end

    def expire(_key, _seconds)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end
  end
end
