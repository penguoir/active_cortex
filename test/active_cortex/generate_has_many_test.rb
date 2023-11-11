require "test_helper"

class GenerateHasManyTest < ActiveSupport::TestCase
  include WithVCR

  setup do
    @doc = Document.new(text: "ABC")
  end

  test "generates has_many" do
    assert_empty @doc.reviews

    with_expiring_vcr_cassette do
      assert_no_difference "Review.count" do
        @doc.generate_reviews!
      end
    end

    assert_equal 3, @doc.reviews.size
    assert_operator @doc.reviews[0].text.size, :>, 10
    assert_equal 5, @doc.reviews[0].rating
  end

  test "does not save the generated has_many records" do
    with_expiring_vcr_cassette do
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

    with_expiring_vcr_cassette do
      @doc.generate_reviews!
    end

    assert_equal 1, @doc.reviews.size
  end

  test "no limit to generation when max_results is empty" do
    class DocumentWithNoLimit < Document
      ai_generated :reviews,
        prompt: :reviews_prompt,
        max_results: nil
    end

    @doc = DocumentWithNoLimit.new(text: "ABC")

    with_expiring_vcr_cassette do
      @doc.generate_reviews!
    end
  end

  test "tool calls in parallel" do
    class DocumentWithParallelReviewGeneration < Document
      ai_generated :reviews,
        prompt: -> (doc) { "In parallel, register three reviews for the following: #{doc.text}" },
        max_results: 3
    end

    @doc = DocumentWithParallelReviewGeneration.new(text: "ABC")

    with_expiring_vcr_cassette do
      @doc.generate_reviews!
    end

    assert_equal 3, @doc.reviews.size
  end

  test "tool calls in parallel with no limit" do
    class DocumentWithParallelReviewGeneration < Document
      ai_generated :reviews,
        prompt: -> (doc) { "In parallel, register three reviews for the following: #{doc.text}" },
        max_results: nil
    end

    @doc = DocumentWithParallelReviewGeneration.new(text: "The chicken crossed the road.")

    with_expiring_vcr_cassette do
      @doc.generate_reviews!
    end

    assert_equal 3, @doc.reviews.size
  end

  test "custom model" do
    class DocumentWithCustomModelToGenerateFields < Document
      ai_generated :reviews,
        prompt: :reviews_prompt,
        max_results: 3,
        model: "gpt-4" # Not the default model
    end

    @doc = DocumentWithCustomModelToGenerateFields.new(text: "ABC")

    with_expiring_vcr_cassette do
      @doc.generate_reviews!
    end

    assert_requested(:post, "https://api.openai.com/v1/chat/completions") { |req|
      JSON.parse(req.body)["model"] == "gpt-4"
    }
  end
end
