# frozen_string_literal: true

module Toggleable
  # Toggleable::Configuration yields the configuration of toggleable.
  class Configuration
    attr_accessor :expiration_time ## expiration time for memoization. default: 5 minutes
    attr_accessor :storage ## storage used. default: memory store
    attr_accessor :namespace ## required for prefixing the keys. default: `toggleable``
    attr_accessor :logger ## optional, it will not log if not configured.
    attr_accessor :use_memoization ## set true to use memoization. default: false
    attr_accessor :notify_host ## optional for notify changes on telegram
    attr_accessor :blacklisted_notif_key ## optional for blacklisting keys that won't be broadcasted
  end
end
