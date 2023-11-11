require "openai"

module ActiveCortex::Model
  extend ActiveSupport::Concern

  class_methods do
    def ai_generated(field, prompt: nil, max_results: nil)
      define_method("generate_#{field}!") do
        if self.class.reflect_on_association(field)&.collection?
          result = generate_has_many(field, prompt: prompt, max_results: max_results)
          self.send(field).push(result)
        else
          self.send("#{field}=", generate_content_for_field(field, prompt:))
        end
      end
    end
  end

  private

  def generate_has_many(field, prompt: nil, results: [], max_results: nil)
    content = case prompt
              when Symbol then send(prompt)
              when Proc then prompt.call(self)
              else
                raise ActiveCortex::Error, "prompt must be a symbol or a proc"
              end

    klass = self.class.reflect_on_association(field).klass

    res = openai_client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        { role: "user", content: content },
        *results.map do |result_arguments|
          [{
            role: "assistant",
            content: nil,
            tool_calls: [{
              id: "TODO",
              type: "function",
              function: {
                name: "register_#{klass.name.singularize.underscore}",
                arguments: result_arguments.to_json,
              },
              finish_reason: "tool_calls",
            }]
          },
          {
            tool_call_id: "TODO",
            role: "tool",
            name: "register_#{klass.name.singularize.underscore}",
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
    
    args = res["choices"][0]["message"]["tool_calls"][0]["function"]["arguments"]

    attrs = JSON.parse(args)
    results << attrs

    if results.count >= max_results
      results.map { |attrs| klass.new(attrs) }
    else
      generate_has_many(field, prompt: prompt, results: results, max_results: max_results)
    end
  end

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
