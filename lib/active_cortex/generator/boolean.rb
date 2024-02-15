class ActiveCortex::Generator::Boolean < ActiveCortex::Generator
  def self.accepts?(record:, field_name:)
    record.class.attribute_types[field_name.to_s].type == :boolean
  end

  def self.generate(record:, field_name:)
    record.send("#{field_name}=", generation)
  end

  def generation
    openai_content || raise(ActiveCortex::Error, openai_error_message)
  end

  private

  def convert_to_boolean(content)
    case content
    when "Yes", "yes", "True", "true", "1"
      true
    when "No", "no", "False", "false", "0"
      false
    else
      raise ActiveCortex::Error, "Could not convert content to boolean: #{content}"
    end
  end

  def openai_content
    convert_to_boolean(openai_response["choices"][0]["message"]["content"])
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
