class Document < ApplicationRecord
  include ActiveCortex::Model

  has_many :reviews

  ai_generated :summary, prompt: -> (doc) { "Summarize: #{doc.text}" }
  ai_generated :reviews, prompt: :reviews_prompt, max_results: 3

  private

  def reviews_prompt
    "Register three reviews for the following summary of a document: #{summary}"
  end
end
