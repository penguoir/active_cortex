class Document < ApplicationRecord
  include ActiveCortex::Model

  ai_generated :summary, prompt: -> (doc) { "Summarize: #{doc.text}" }
end
