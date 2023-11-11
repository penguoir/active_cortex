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
  end

  test "does not save the generated has_many" do
    stub_generating_reviews do
      assert_no_difference "Review.count" do
        @doc.generate_reviews!
      end
    end
  end

  private

  def stub_generating_reviews
    VCR.use_cassette("GenerateHasManyTest/generates_three_reviews") do
      yield
    end
  end
end
