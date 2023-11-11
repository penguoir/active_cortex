require "test_helper"

class GenerateHasManyTest < ActiveSupport::TestCase
  setup do
    @doc = Document.new(text: "ABC")
  end

  test "generates has_many" do
    assert_empty @doc.reviews

    stub_generating_reviews do
      assert_no_difference "Review.count" do
        @doc.generate_reviews!
      end
    end

    assert_equal 3, @doc.reviews.size
    assert_equal "Excellent summary, very clear and concise.", @doc.reviews[0].text
    assert_equal 5, @doc.reviews[0].rating
  end

  test "does not save the generated has_many records" do
    stub_generating_reviews do
      assert_no_difference "Review.count" do
        @doc.generate_reviews!
      end
    end
  end

  test "max_results" do
    class DocumentWithOneReview < Document
      ai_generated :reviews,
        prompt: :reviews_prompt,
        max_results: 1
    end

    @doc = DocumentWithOneReview.new(text: "ABC")

    stub_generating_reviews do
      @doc.generate_reviews!
    end

    assert_equal 1, @doc.reviews.size
  end

  private

  def stub_generating_reviews
    VCR.use_cassette("GenerateHasManyTest/generates_three_reviews") do
      yield
    end
  end
end
