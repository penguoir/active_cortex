# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

require "minitest/mock"
require 'webmock/minitest'
require 'vcr'

Dotenv.load!
ActiveCortex.config.openai_access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<OPENAI_ACCESS_TOKEN>") { ENV.fetch("OPENAI_ACCESS_TOKEN") }
  config.default_cassette_options = {
    match_requests_on: [:method, :uri, :body],
    drop_unused_requests: true
  }
end

module WithVCR
  private

  def with_expiring_vcr_cassette
    names = self.class.name.split("::") + [name]
    cassette_path = names.map { |s| s.gsub(/[^A-Z0-9]+/i, "_") }.join("/")

    VCR.use_cassette(cassette_path) do |cassette|
      if File.exist?(cassette.file)
        age = Time.current - File.mtime(cassette.file)
        FileUtils.rm(cassette.file) if age > 1.month
      end
      begin
        yield(cassette)
      rescue StandardError
        FileUtils.rm(cassette.file) if File.exist?(cassette.file)
        raise
      end
    end
  end
end
