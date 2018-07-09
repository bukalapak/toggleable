# frozen_string_literal: true

require 'active_support/cache'

module Toggleable
  # Toggleable::selfAbstract describes the interface class for
  class MemoryStore < ActiveSupport::Cache::MemoryStore
    ## the self you provide must implement these methods
    ## namespace parameter is optional, only if you provide namespace configuration

    def get(key, namespace:)
      read(key, namespace: namespace)
    end

    def get_all(namespace:)
      read_multi(*keys, namespace: namespace)
    end

    def set(key, value, namespace:)
      write(key, value, namespace: namespace)
    end

    def set_if_not_exist(key, value, namespace:)
      fetch(key, namespace: namespace) do
        value
      end
    end

    def mass_set(mappings, namespace:)
      write_multi(mappings, namespace: namespace)
    end

    def keys
      cache_keys = @data.keys
      normalize_keys(cache_keys)
    end

    private

    def normalize_keys(cache_keys)
      cache_keys.map{ |k| k.sub("#{Toggleable.configuration.namespace}:", '') }
    end
  end
end
