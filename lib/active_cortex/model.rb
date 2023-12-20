require "openai"

module ActiveCortex::Model
  extend ActiveSupport::Concern

  DEFAULT_MODEL = "gpt-3.5-turbo"

  class_methods do
    # Macro to add methods to a model to generate content for a field.
    #
    # For has_many associations, the macro will generate a method that appends an array of
    # generated objects to the association.
    #
    # Example:
    #
    #     class Post < ApplicationRecord
    #       ai_generated :title, prompt: -> (post) { "Write a title for a post about #{post.topic}" }
    #     end
    #
    #     post = Post.new(topic: "cats")
    #     post.generate_title!
    #     post.title # => "Cats are the best"
    #
    # Example with has_many association:
    #
    #    class Post < ApplicationRecord
    #      has_many :comments
    #      ai_generated :comments,
    #        prompt: -> (post) { "Register a comment on #{post.title}" },
    #        max_results: 3
    #    end
    #
    #    post = Post.new(title: "Cats are the best")
    #    post.generate_comments!
    #    post.comments # => [#<Comment id: 1, content: "I love cats">, ...]
    #
    # Options:
    #
    #   * prompt: a symbol or a proc that returns a string to use as the prompt
    #   * model: the ChatGPT model to use for generating content
    #   * max_results: for has_many associations, the maximum number of results to generate
    def ai_generated(field_name, prompt:, max_results: nil, model: DEFAULT_MODEL)
      validate_arguments!(field_name, prompt, max_results, model)

      define_method "generate_#{field_name}!" do
        ActiveCortex::Generator.generate(
          record: self, field_name:, prompt:, max_results:, model:
        )
      end
    end

    private

    def validate_arguments!(field_name, prompt, max_results, model)
      raise ArgumentError, "field_name must be a symbol or string" unless field_name.is_a?(Symbol) || field_name.is_a?(String)
      raise ArgumentError, "prompt must be a proc" unless prompt.is_a?(Proc) || prompt.is_a?(Symbol)
      raise ArgumentError, "max_results must be a number" unless max_results.nil? || max_results.is_a?(Integer)
      raise ArgumentError, "model must be a string" unless model.is_a?(String)
    end
  end
end
