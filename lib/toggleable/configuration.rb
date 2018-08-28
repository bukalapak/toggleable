# frozen_string_literal: true

module Toggleable
  # Toggleable::Configuration yields the configuration of toggleable.
  class Configuration
    attr_accessor :expiration_time ## expiration time for memoization. default: 5 minutes
    attr_accessor :palanca_host
    attr_accessor :palanca_user
    attr_accessor :palanca_password
    attr_accessor :storage ## storage used. default: memory store
    attr_accessor :namespace ## required for prefixing the keys. default: `toggleable``
    attr_accessor :logger ## optional, it will not log if not configured.
    attr_accessor :use_memoization ## set true to use memoization. default: false
  end
end
