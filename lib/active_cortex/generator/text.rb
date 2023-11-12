class ActiveCortex::Generator::Text < ActiveCortex::Generator
  def self.accepts?(record:, field_name:)
    record.class.attribute_types[field_name.to_s].type == :string
  end

  def save_generation
    record.send("#{field_name}=", generation)
  end

  def generation
    message = openai_response.dig("choices", 0, "message", "content")
    return message if message.present?
    raise ActiveCortex::Error, error_message
  end

  private

  def openai_response
    @openai_response ||= openai_client.chat(parameters: {
      model: model,
      messages: [
        { role: "user", content: prompt }
      ],
    })
  end

  def error_message
    openai_response["error"] || "Unknown error from OpenAI. " +
      { response: openai_response }.to_json
  end
end
