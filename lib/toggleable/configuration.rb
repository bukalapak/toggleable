module Toggleable
  class Configuration
    attr_accessor :expiration_time ## expiration time for memoization.
    attr_accessor :storage ## storage used.
    attr_accessor :namespace ## optional, if you use certain namespace
    attr_accessor :logger ## optional, it will not log if not configured.
    attr_accessor :use_memoization  ## set true to use memoization.

    def initialize
      @storage = Toggleable::StorageAbstract.new
    end
  end
end
