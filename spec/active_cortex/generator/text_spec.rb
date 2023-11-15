RSpec.describe ActiveCortex::Generator::Text do
  let(:book) { Book.new(title: "The Great Gatsby") }
  let(:generator) { 
    ActiveCortex::Generator::Text.new(
      model: "gpt-3.5-turbo",
      record: book,
      field_name: :summary,
      max_results: nil,
      prompt: -> (book) { "Write a summary of the book #{book.title}" }
    )
  }

  it "accepts text fields" do
    expect(ActiveCortex::Generator::Text.accepts?(record: book, field_name: :title)).to be_truthy
    expect(ActiveCortex::Generator::Text.accepts?(record: book, field_name: :summary)).to be_truthy
    expect(ActiveCortex::Generator::Text.accepts?(record: book, field_name: :reviews)).to be_falsey
  end

  context "when saving generation" do
    it "assigns field=" do
      expect(book).to receive(:summary=).with("A summary")
      expect(generator).to receive(:generation).and_return("A summary")
      generator.save_generation
    end

    it "does not persist the record" do
      expect(generator).to receive(:generation).and_return("A summary")
      generator.save_generation
      expect(book).not_to be_persisted
    end
  end

  context "when generating" do
    it "creates a text generation", :vcr do
      result = generator.generation
      expect(result).to be_a(String)
    end
  end

  context "when OpenAI returns an error" do
    it "raises an error" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(status: 500)
      expect { generator.generation }.to raise_error(ActiveCortex::Error)

      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(status: 400)
      expect { generator.generation }.to raise_error(ActiveCortex::Error)

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 200, body: '{}')
      expect { generator.generation }.to raise_error(ActiveCortex::Error)
    end
  end
end
