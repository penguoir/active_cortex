require "test_helper"

class ModelTest < ActiveSupport::TestCase
  setup do
    stub_chatgpt
    @doc = Document.new(text: "ABC")
  end

  test "defines the ai_generated macro" do
    assert_respond_to Document, :ai_generated
  end

  test "it adds #generate_[ai_field]" do
    assert_nil @doc.summary
    assert_respond_to @doc, :generate_summary!
    @doc.generate_summary!
    assert_predicate @doc.summary, :present?
  end

  test "generate_summary! queries ChatGPT with the provided prompt" do
    assert_nil @doc.summary
    @doc.generate_summary!
    assert_equal "response for Summarize: ABC", @doc.summary
  end

  test "generate_summary! raises an error on fail" do
    stub_chatgpt(with: 500)

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
    @doc.generate_summary!
    assert_equal "response for Summarize: ABC", @doc.summary
  end

  private

  def stub_chatgpt(with: nil)
    if with == 500
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 500, body: {}.to_json, headers: {})

      return
    end

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with({
        body: {
          model: "gpt-3.5-turbo",
          messages: [{
            role: "user",
            content: "Summarize: ABC"
          }]
        }.to_json,
        headers: {
	  'Accept'=>'*/*',
	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>"Bearer #{ActiveCortex.config.openai_access_token}",
	  'Content-Type'=>'application/json',
	  'User-Agent'=>'Ruby'
        }
      }).to_return(status: 200, body: {
        choices: [
          message: {
            content: "response for Summarize: ABC"
          }
        ]
      }.to_json, headers: {})
  end

end
