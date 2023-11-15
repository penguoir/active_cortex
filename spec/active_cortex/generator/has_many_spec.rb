RSpec.describe ActiveCortex::Generator::HasMany do
  let(:book) { Book.new(title: "The Great Gatsby") }
  let(:generator) { 
    ActiveCortex::Generator::Text.new(
      model: "gpt-3.5-turbo",
      record: book,
      field_name: :reviews,
      max_results: 2,
      prompt: -> (book) { "Register two reviews of the book #{book.title}" }
    )
  }

  it "accepts has_many fields" do
    expect(ActiveCortex::Generator::HasMany.accepts?(record: book, field_name: :reviews)).to be_truthy
    expect(ActiveCortex::Generator::HasMany.accepts?(record: book, field_name: :title)).to be_falsey
  end

  context "when saving generation" do
    before do
      expect(generator).to receive(:generation).and_return([
        Review.new(content: "A review")
      ])

      generator.save_generation
    end

    it "appends to the association" do
      expect(book.reviews.size).to eq(1)
    end

    it "does not persist the records" do
      expect(book.reviews.count).to eq(0)
    end
  end

  context "when generating with max_results" do
    # TODO
  end

  context "when generating without max_results" do
    # TODO
  end

  context "when generating with parallel model with max_results" do
    # TODO
  end

  context "when generating with parallel model without max_results" do
    # TODO
  end

  context "when OpenAI returns an error" do
    it "raises an error" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 500)
      expect { generator.generation }.to raise_error(ActiveCortex::Error)

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 400)
      expect { generator.generation }.to raise_error(ActiveCortex::Error)

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 200, body: '{}')
      expect { generator.generation }.to raise_error(ActiveCortex::Error)
    end
  end
end
