module Toggleable
  class Configuration
    attr_accessor :expiration_time ## expiration time for memoization
    attr_accessor :storage ## storage used
    attr_accessor :use_memoization  ## set true to use memoization
  end
end
