module Toggleable
  class RedisConfiguration
    attr_accessor :hosts
    attr_accessor :redis_opts
    attr_accessor :cluster_opts
  end
end
