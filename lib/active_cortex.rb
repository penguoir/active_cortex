require "active_cortex/version"
require "active_cortex/config"
require "active_cortex/railtie"
require "active_cortex/generator"
require "active_cortex/generator/text"
require "active_cortex/generator/has_many"
require "active_cortex/generator/boolean"
require "active_cortex/model"

module ActiveCortex
  class Error < StandardError; end
end
