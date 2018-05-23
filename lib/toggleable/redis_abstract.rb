module Toggleable
  class RedisAbstract
    REQUIRED_METHODS = ['get', 'set', 'hget', 'hgetall', 'hset', 'hsetnx', 'hmset', 'expire'].freeze

    REQUIRED_METHODS.each do |method|
      define_method("#{method}") do |*args|
        raise NotImplementedError.new("You must implement #{method}")
      end
    end
  end
end
