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

  test "no limit to generation when max_results is empty" do
    class DocumentWithNoLimit < Document
      ai_generated :reviews,
        prompt: :reviews_prompt,
        max_results: nil
    end

    @doc = DocumentWithNoLimit.new(text: "ABC")

    stub_generating_reviews_with_no_limit do
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

    stub_generating_reviews_in_parallel do
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

    stub_generating_reviews_with_no_limit_in_parallel do
      @doc.generate_reviews!
    end

    assert_equal 3, @doc.reviews.size
  end

  private

  def stub_generating_reviews
    VCR.use_cassette("GenerateHasManyTest/generates_three_reviews") do
      yield
    end
  end

  def stub_generating_reviews_with_no_limit
    VCR.use_cassette("GenerateHasManyTest/generates_three_reviews_with_no_limit") do
      yield
    end
  end

  def stub_generating_reviews_in_parallel
    VCR.use_cassette("GenerateHasManyTest/generates_three_reviews_in_parallel") do
      yield
    end
  end

  def stub_generating_reviews_with_no_limit_in_parallel
    VCR.use_cassette("GenerateHasManyTest/generates_three_reviews_with_no_limit_in_parallel") do
      yield
    end
  end
end
