module Toggleable
  class Configuration
    attr_accessor :expiration_time ## expiration time for memoization
    attr_accessor :redis ## redis instance used
    attr_accessor :development_mode  ## set true for development
  end
end
