require "test_helper"

class ActiveCortex::GeneratorTest < ActiveSupport::TestCase
  test ".generate uses text generator" do
    doc = Document.new(text: "ABC")
    ActiveCortex::Generator::Text.stub_any_instance(:generation, "summary") do
      doc.generate_summary!
    end
    assert_equal "summary", doc.summary
  end

  test ".generate uses has_many generator" do
    doc = Document.new(text: "ABC")
    reviews = [Review.new(text: "comment")]
    ActiveCortex::Generator::HasMany.stub_any_instance(:generation, reviews) do
      doc.generate_reviews!
    end
    assert_equal reviews, doc.reviews
    assert_equal 0, Review.count
  end

  test "raises for unknown field type" do
    class DocumentWithOneReview < Document
      has_one :review
      ai_generated :review, prompt: -> (doc) { "valid" }
    end

    doc = DocumentWithOneReview.new(text: "ABC")

    assert_raises(ActiveCortex::Error) do
      doc.generate_review!
    end
  end

  test "raises for unknown field name" do
    class DocumentWithUnknownAIGeneratedField < Document
      ai_generated :unknown, prompt: -> (doc) { "valid" }
    end

    doc = DocumentWithUnknownAIGeneratedField.new(text: "ABC")

    error = assert_raises(ActiveCortex::Error) do
      doc.generate_unknown!
    end

    assert_equal "No generator found for 'unknown'", error.message
  end

  test "invalid model raises" do
    assert_raises(ArgumentError) do
      ActiveCortex::Generator.new(
        record: Document.new,
        field_name: :summary,
        prompt: -> (doc) { "valid" },
        max_results: nil,
        model: Document # not a string
      )
    end

    ActiveCortex::Generator.new(
      record: Document.new,
      field_name: :summary,
      prompt: -> (doc) { "valid" },
      max_results: nil,
      model: "gpt-3.5-turbo"
    )
  end
end
