require_relative "lib/active_cortex/version"

Gem::Specification.new do |spec|
  spec.name        = "active_cortex"
  spec.version     = ActiveCortex::VERSION
  spec.authors     = ["Ori Marash"]
  spec.email       = ["ori@marash.net"]
  spec.homepage    = "https://github.com/penguoir/active_cortex"
  spec.summary     = "Easily add AI-generated fields to your Rails models."
  spec.description = "Easily add AI-generated fields to your Raila models."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/penguoir/active_cortex"
  spec.metadata["changelog_uri"] = "https://github.com/penguoir/active_cortex"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.8"
  spec.add_dependency "dry-configurable", ">= 1.0"
  spec.add_dependency "ruby-openai", ">= 5.1"
end
