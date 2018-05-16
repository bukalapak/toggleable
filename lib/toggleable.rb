# Provides a common interface for toggling features
require "toggleable/version"
require "toggleable/feature_toggler"
require "toggleable/base"
require "toggleable/schedule"
require "toggleable/redis_configuration"

module Toggleable
  class << self
    attr_accessor :configuration
  end

  module_function

  def configuration
    @configuration ||= Toggleable::RedisConfiguration.new
  end

  def configure
    yield(configuration)
    $redis_host = RedisCluster.new(configuration.hosts, cluster_opts: configuration.cluster_opts, redis_opts: configuration.redis_opts)
  end
end
