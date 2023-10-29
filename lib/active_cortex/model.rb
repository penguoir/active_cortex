require "openai"

module ActiveCortex::Model
  extend ActiveSupport::Concern

  class_methods do
    def ai_generated(field, prompt: nil)
      define_method("generate_#{field}!") do
        self[field] = generate_content_for_field(field, prompt:)
      end
    end
  end

  private

  def generate_content_for_field(field, prompt: nil)
    content = case prompt
              when Symbol then send(prompt)
              when Proc then prompt.call(self)
              else
                raise ActiveCortex::Error, "prompt must be a symbol or a proc"
              end

    query_chatgpt_with(content)
  rescue => e
    raise ActiveCortex::Error, e.message
  end

  def query_chatgpt_with(content)
    openai_client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: content }], 
    })["choices"][0]["message"]["content"]
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new(access_token: ActiveCortex.config.openai_access_token)
  end
end
