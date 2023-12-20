require 'active_cortex'

RSpec.describe ActiveCortex::Model do
  let(:book) { Book.new(title: "The Great Gatsby") }

  before do
    Book.include ActiveCortex::Model
  end

  context "when included in a model" do
    it "adds the .ai_generated class method" do
      expect(Book).to respond_to(:ai_generated)
    end
  end

  describe ".ai_generated" do
    context "when called with valid arguments" do
      before do
        Book.ai_generated :summary,
          prompt: -> (book) { "Write a short summary of #{book.title}" }

        Book.ai_generated :reviews, prompt: :generate_reviews_prompt
      end

      it "adds a generate function for the provided field" do
        expect(book).to respond_to(:generate_summary!)
        expect(book).to respond_to(:generate_reviews!)
      end
    end

    context "when called with invalid arguments" do
      it "raises an error if the field is not a string or symbol" do
        expect do
          Book.ai_generated 1
        end.to raise_error(ArgumentError)
      end

      it "raises an error if the prompt is not a proc or function name" do
        expect do
          Book.ai_generated :summary, prompt: "Write a summary"
        end.to raise_error(ArgumentError)
      end

      it "raises an error if the max_results is not an integer" do
        expect do
          Book.ai_generated :summary, prompt: -> (book) { "Write a summary" }, max_results: "3"
        end.to raise_error(ArgumentError)
      end

      it "raises an error if the model is not a string" do
        expect do
          Book.ai_generated :summary, prompt: -> (book) { "Write a summary" }, model: Book
        end.to raise_error(ArgumentError)
      end
    end
  end

  context "when populating text fields" do
    let(:prompt_proc) { -> (book) { "Write a short summary of #{book.title}" } }

    before do
      Book.ai_generated :summary, prompt: prompt_proc
    end

    it "generates content and saves it", :vcr do
      book.generate_summary!
      expect(book.summary).to be_present
    end
  end

  context "when populating has_many fields" do
    let(:prompt_proc) { -> (book) { "Register three reviews for the #{book.title}" } }

    before do
      Book.ai_generated :reviews, prompt: prompt_proc, max_results: 3
    end

    it "generates content and saves it", :vcr do
      book.generate_reviews!
      expect(book.reviews.size).to eq(3)
      expect(book.reviews.first).to be_a(Review)
      expect(book.reviews.first).not_to be_persisted
    end
  end
end
