require "test_helper"

class ModelTest < ActiveSupport::TestCase
  include WithVCR

  setup do
    @doc = Document.new(text: "ABC")
  end

  test "defines the ai_generated macro" do
    assert_respond_to Document, :ai_generated
  end

  # TODO: some high-level e2e tests
end
