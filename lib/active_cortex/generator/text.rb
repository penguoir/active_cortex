class ActiveCortex::Generator::Text < ActiveCortex::Generator
  def self.accepts?(record:, field_name:)
    record.class.attribute_types[field_name.to_s].type == :string
  end

  def save_generation
    record.send("#{field_name}=", generation)
  end

  def generation
    openai_content || raise(ActiveCortex::Error, openai_error_message)
  end

  private

  def openai_content
    openai_response["choices"][0]["message"]["content"]
  rescue
    nil
  end

  def openai_error_message
    "Error from OpenAI. " + { response: openai_response }.to_json
  end

  def openai_response
    @openai_response ||= openai_client.chat(parameters: {
      model: model,
      messages: [
        { role: "user", content: prompt }
      ],
    })
  end
end
