# frozen_string_literal: true

# this module includes all storage implementations listed on /storage/*.
module Toggleable
  Dir[File.dirname(__FILE__) + '/storage/*.rb'].each{ |file| require file }
end
