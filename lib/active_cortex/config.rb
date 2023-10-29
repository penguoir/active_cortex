require "dry-configurable"

module ActiveCortex
  extend Dry::Configurable

  setting :openai_access_token
end
