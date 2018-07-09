# frozen_string_literal: true

require 'toggleable/storage/abstract'

module Toggleable
  # Toggleable::RedisStore is storage implementation using redis, you should specify namespace to use it.
  # Also pass the redis instance used in when initializing.
  class RedisStore < Toggleable::StorageAbstract
    attr_accessor :storage

    def initialize(redis_instance)
      @storage = redis_instance
    end

    def get(key, namespace:)
      storage.hget(namespace, key)
    end

    def get_all(namespace:)
      storage.hgetall(namespace)
    end

    def set(key, value, namespace:)
      storage.hset(namespace, key, value)
    end

    def set_if_not_exist(key, value, namespace:)
      storage.hsetnx(namespace, key, value)
    end

    def mass_set(mappings, namespace:)
      mappings = mappings.flatten if mappings.is_a? Hash
      storage.hmset(namespace, mappings)
    end
  end
end
