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
    openai_client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt.call(self) }], 
    })["choices"][0]["message"]["content"]
  rescue
    raise ActiveCortex::Error
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new(access_token: ActiveCortex.config.openai_access_token)
  end
end
