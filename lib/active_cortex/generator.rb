class ActiveCortex::Generator
  # This is a factory method that returns an instance of a subclass of
  # ActiveCortex::Generator. The subclass is chosen based on the type of the
  # field that is being generated: text or has_many.
  #
  # The subclass is responsible for generating the result and saving it to the
  # database.

  def self.generate(**)
    find_generator_class(**).new(**).save_generation
  end

  attr_reader :record, :field_name, :prompt, :max_results, :model

  def initialize(record:, field_name:, prompt:, max_results:, model:)
    @record = record
    @field_name = field_name
    @prompt = prompt
    @max_results = max_results
    @model = model

    raise ArgumentError, "Invalid model provided must be " \
      "e.g. 'gpt-3.5-turbo', was #{model.inspect}" unless valid_model?
  end

  def generation
    raise NotImplementedError
  end

  def save_generation
    raise NotImplementedError
  end

  private

  def self.find_generator_class(record:, field_name:, **)
    subclasses.find do |subclass|
      subclass.accepts?(record:, field_name:)
    end or raise(ActiveCortex::Error, "No generator found for '#{field_name}'")
  end

  def prompt
    case @prompt
    when Symbol then @record.send(@prompt)
    when Proc then @prompt.call(@record)
    else
      raise ActiveCortex::Error,
        "Prompt must be a symbol or a proc, got #{@prompt.inspect}"
    end
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new(access_token: ActiveCortex.config.openai_access_token)
  end

  def valid_model?
    model.present? && model.is_a?(String)
  end
end
