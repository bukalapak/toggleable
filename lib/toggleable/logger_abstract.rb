module Toggleable
  class LoggerAbstract
    ## the redis you provide must implement these methods

    def log(key:, value: ,actor:)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end
  end
end
