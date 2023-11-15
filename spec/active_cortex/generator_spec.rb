RSpec.describe ActiveCortex::Generator do
  before do
    Book.include ActiveCortex::Model
  end

  let(:book) { Book.new(title: "The Great Gatsby") }

  describe "choosing a generator" do
    context "when the field is a string", :vcr do
      let(:prompt_proc) { -> (book) { "Write a summary of the book #{book.title}" } }

      it "generates text", :vcr do
        ActiveCortex::Generator.generate(
          model: "gpt-3.5-turbo",
          record: book,
          field_name: :summary,
          prompt: prompt_proc,
          max_results: nil
        )

        expect(book.summary).to be_a(String)
      end
    end

    context "when the field is a has_many", :vcr do
      let(:prompt_proc) { -> (book) { "Register three reviews about #{book.title}" } }

      it "generates associations", :vcr do
        ActiveCortex::Generator.generate(
          model: "gpt-3.5-turbo",
          record: book,
          field_name: :reviews, 
          prompt: prompt_proc,
          max_results: 3
        )

        expect(book.reviews.first).to be_a(Review)
      end
    end
  end
end
