require "test_helper"

class ModelTest < ActiveSupport::TestCase
  include WithVCR

  setup do
    @doc = Document.new(text: "ABC")
  end

  test "defines the ai_generated macro" do
    assert_respond_to Document, :ai_generated
  end

  test "it adds #generate_[ai_field]" do
    assert_nil @doc.summary
    assert_respond_to @doc, :generate_summary!

    with_expiring_vcr_cassette do
      @doc.generate_summary!
    end

    assert_predicate @doc.summary, :present?
  end

  test "generate_summary! raises an error on fail" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 500, body: {}.to_json, headers: {})

    assert_raises ActiveCortex::Error do
      @doc.generate_summary!
    end
  end

  test "can provide a method name as a prompt" do
    class DocumentWithSymbolPrompt < Document
      ai_generated :summary, prompt: :generate_summary_prompt

      private

      def generate_summary_prompt
        "Summarize: #{text}"
      end
    end

    @doc = DocumentWithSymbolPrompt.new(text: "ABC")

    assert_nil @doc.summary

    with_expiring_vcr_cassette do
      @doc.generate_summary!
    end

    assert_predicate @doc.summary, :present?
  end

  test "raises an error if the prompt is not a symbol or a proc" do
    class DocumentWithInvalidPrompt < Document
      ai_generated :summary, prompt: "invalid"
    end

    @doc = DocumentWithInvalidPrompt.new(text: "ABC")

    assert_raises ActiveCortex::Error do
      @doc.generate_summary!
    end
  end

  test "custom model" do
    class DocumentWithCustomModel < Document
      ai_generated :summary, prompt: -> (doc) { "Summarize: #{doc.text}" }, model: "gpt-4"
    end

    @doc = DocumentWithCustomModel.new(text: "ABC")

    VCR.use_cassette("ModelTest/custom_model") do
      @doc.generate_summary!
    end

    assert_requested(:post, "https://api.openai.com/v1/chat/completions") { |req|
      JSON.parse(req.body)["model"] == "gpt-4"
    }
  end
end
