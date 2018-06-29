module Toggleable
  class LoggerAbstract
    ## the redis you provide must implement these methods

    def log(name:, value: ,actor:)
      raise NotImplementedError.new("You must implement #{__method__.to_s}")
    end
  end
end
