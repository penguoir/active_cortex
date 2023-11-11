require "openai"

module ActiveCortex::Model
  extend ActiveSupport::Concern

  class_methods do
    def ai_generated(field, prompt: nil, max_results: nil, model: DEFAULT_MODEL)
      define_method("generate_#{field}!") do
        if self.class.reflect_on_association(field)&.collection?
          result = generate_has_many(field, prompt: prompt, max_results: max_results, model: model)
          self.send(field).push(result)
        else
          self.send("#{field}=", generate_content_for_field(field, prompt:, model: model))
        end
      end
    end
  end

  private

  DEFAULT_MODEL = "gpt-3.5-turbo"

  def generate_has_many(field, prompt: nil, tool_calls: [], max_results: nil, model:)
    content = case prompt
              when Symbol then send(prompt)
              when Proc then prompt.call(self)
              else
                raise ActiveCortex::Error, "prompt must be a symbol or a proc"
              end

    klass = self.class.reflect_on_association(field).klass

    res = openai_client.chat(parameters: {
      model: model,
      messages: [
        { role: "user", content: content },
        *tool_calls.map do |tool_call|
          [{
            role: "assistant",
            content: nil,
            tool_calls: [tool_call]
          },
          {
            tool_call_id: tool_call["id"],
            role: "tool",
            name: tool_call["function"]["name"],
            content: "OK",
          }]
        end.flatten
      ], 
      tools: [{
        type: "function",
        function: {
          description: "Register a #{klass.name.singularize}", # TODO: test
          name: "register_#{klass.name.singularize.underscore}", # TODO: test
          parameters: {
            type: "object",
            properties: klass.column_names
              .reject { |c| ["id", "created_at", "updated_at"].include?(c) }
              .reject { |c| c.end_with?("_id") }
              .map { |c| [c, { type: "string" }] }
              .to_h
          }
        }
      }]
    })

    raise ActiveCortex::Error, res["error"] if res["error"]

    # Break when there is no tool call
    if res["choices"][0]["message"]["tool_calls"].blank?
      return tool_calls.map do |tool_call|
        attrs_json = tool_call["function"]["arguments"]
        attrs = JSON.parse(attrs_json)

        if attrs.is_a?(Array)
          attrs.map { |a| klass.new(a) }
        else
          klass.new(attrs)
        end
      end
    end

    tool_calls += res["choices"][0]["message"]["tool_calls"]

    if max_results && tool_calls.count >= max_results
      return tool_calls.map do |tool_call|
        attrs_json = tool_call["function"]["arguments"]
        attrs = JSON.parse(attrs_json)

        if attrs.is_a?(Array)
          attrs.map { |a| klass.new(a) }
        else
          klass.new(attrs)
        end
      end
    else
      generate_has_many(field, prompt: prompt, tool_calls: tool_calls, max_results: max_results, model: model)
    end
  end

  def generate_content_for_field(field, prompt: nil, model:)
    content = case prompt
              when Symbol then send(prompt)
              when Proc then prompt.call(self)
              else
                raise ActiveCortex::Error, "prompt must be a symbol or a proc"
              end

    query_chatgpt_with(content, model: model)
  rescue => e
    raise ActiveCortex::Error, e.message
  end

  def query_chatgpt_with(content, model:)
    openai_client.chat(parameters: {
      model: model,
      messages: [{ role: "user", content: content }], 
    })["choices"][0]["message"]["content"]
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new(access_token: ActiveCortex.config.openai_access_token)
  end
end
