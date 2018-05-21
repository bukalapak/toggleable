module Toggleable
  class Configuration
    attr_accessor :expiration_time
    attr_accessor :redis

    def redis=(redis)
      raise TypeError.new('The argument must be an instance of redis') unless valid_object? redis
      self.redis = redis
    end

    private

    def valid_object?(redis)
      redis.is_a? Redis || redis.is_a? RedisCluster
    end
  end
end
