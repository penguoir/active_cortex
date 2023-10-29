require "test_helper"

class ActiveCortexTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "it has a version number" do
    assert ActiveCortex::VERSION
  end

  test "it is configurable" do
    before = ActiveCortex.config.openai_access_token
    assert_equal "openai-access-token-placeholder", before

    ActiveCortex.config.openai_access_token = "test"
    assert_equal "test", ActiveCortex.config.openai_access_token

    ActiveCortex.config.openai_access_token = before
  end
end
