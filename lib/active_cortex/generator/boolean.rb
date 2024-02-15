class ActiveCortex::Generator::Boolean < ActiveCortex::Generator
  def self.accepts?(record:, field_name:)
    record.class.attribute_types[field_name.to_s].type == :boolean
  end

  def save_generation
    record.send("#{field_name}=", generation)
  end

  def generation
    openai_content_as_boolean || raise(ActiveCortex::Error, openai_error_message)
  end

  private

  def openai_content_as_boolean
    convert_to_boolean(openai_content)
  end

  def openai_content
    openai_response["choices"][0]["message"]["content"]
  rescue
    nil
  end

  def openai_error_message
    "Error from OpenAI. " + { response: openai_response }.to_json
  end

  def convert_to_boolean(content)
    content = content&.downcase&.gsub(/[^a-z]/, "")

    case content
    when "yes", "true", "1"
      true
    when "no", "false", "0"
      false
    else
      raise ActiveCortex::Error, "Could not convert content to boolean: #{content}"
    end
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
