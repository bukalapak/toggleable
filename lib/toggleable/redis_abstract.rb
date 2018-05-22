module Toggleable
  class RedisAbstract

    def get
      raise NotImplementedError.new('You must implement this method')
    end

    def set
      raise NotImplementedError.new('You must implement this method')
    end

    def hget
      raise NotImplementedError.new('You must implement this method')
    end

    def hset
      raise NotImplementedError.new('You must implement this method')
    end

    def hgetall
      raise NotImplementedError.new('You must implement this method')
    end

    def hsetnx
      raise NotImplementedError.new('You must implement this method')
    end

    def hmset
      raise NotImplementedError.new('You must implement this method')
    end

    def expire
      raise NotImplementedError.new('You must implement this method')
    end
  end
end
