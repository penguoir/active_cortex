RSpec.describe ActiveCortex::Generator::Boolean do
  let(:book) { Book.new(title: 'The Great Gatsby') }

  let(:generator) {
    ActiveCortex::Generator::Boolean.new(
      model: "gpt-3.5-turbo",
      record: book,
      field_name: :completed,
      max_results: nil,
      prompt: -> (book) { "Is the book '#{book.title}' a finished work? Output only Yes or No." }
    )
  }

  context "when generating" do
    it "returns a boolean", :vcr do
      result = generator.generation
      expect(result).to be_a(TrueClass).or be_a(FalseClass)
    end
  end

  context "when OpenAI returns an error" do
    it "raises an error" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(status: 500)
      expect { generator.generation }.to raise_error(ActiveCortex::Error)
    end
  end

  context "when saving the generation" do
    it "saves the generation to the record", :vcr do
      generator.save_generation
      expect(book.completed).to be_a(TrueClass).or be_a(FalseClass)
    end
  end
end
