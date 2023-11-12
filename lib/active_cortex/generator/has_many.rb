class ActiveCortex::Generator::HasMany < ActiveCortex::Generator
  def self.accepts?(record:, field_name:)
    record.class.reflect_on_association(field_name)&.collection?
  end

  def save_generation
    record.send("#{field_name}=", generation)
  end

  def generation
    generate_tool_calls.map do |tool_call|
      build_record_from_tool_call(tool_call)
    end
  end

  private

  def klass
    record.class.reflect_on_association(field_name).klass
  end

  def klass_attributes
    klass.attribute_types
      .reject { |name, _| ["id", "created_at", "updated_at"].include?(name) }
      .reject { |name, _| name.end_with?("_id") }
      .map    { |name, type| [name, { type: type.type }] }
  end

  def build_messages_from_tool_calls(tool_calls)
    [{ role: "user", content: prompt }] + tool_calls.map do |tool_call|
      [{
        role: "assistant",
        content: nil,
        tool_calls: [tool_call]
      },{
        tool_call_id: tool_call["id"],
        role: "tool",
        name: tool_call["function"]["name"],
        content: "OK"
      }]
    end.flatten
  end

  def schema_for_register_function
    {
      type: "function",
      function: {
        description: "Register a #{klass.name.singularize}", # TODO: test
        name: "register_#{klass.name.singularize.underscore}", # TODO: test
        parameters: {
          type: "object",
          properties: klass_attributes
        }
      }
    }
  end

  def build_objects_from_tool_calls(tool_calls)
    tool_calls.map do |tool_call|
      attrs_json = tool_call["function"]["arguments"]
      attrs = JSON.parse(attrs_json)

      if attrs.is_a?(Array)
        attrs.map { |a| klass.new(a) }
      else
        klass.new(attrs)
      end
    end
  end

  def generate_tool_calls(tool_calls=[])
    res = openai_client.chat(parameters: {
      model: model,
      messages: build_messages_from_tool_calls(tool_calls),
      tools: [schema_for_register_function]
    })

    raise ActiveCortex::Error, res["error"] if res["error"]

    added_tool_calls = res["choices"][0]["message"]["tool_calls"]
    return tool_calls if added_tool_calls.blank?

    tool_calls += added_tool_calls

    if max_results && tool_calls.count >= max_results
      tool_calls
    else
      generate_tool_calls(tool_calls)
    end
  end
end
