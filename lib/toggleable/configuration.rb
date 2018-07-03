module Toggleable
  class Configuration
    attr_accessor :expiration_time ## expiration time for memoization.
    attr_accessor :storage ## storage used.
    attr_accessor :namespace ## storage key namespace
    attr_accessor :logger ## logger used, optional. It will not log if not configured.
    attr_accessor :use_memoization  ## set true to use memoization.

    def initialize
      @storage = Toggleable::StorageAbstract.new
    end
  end
end
