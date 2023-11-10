# ActiveCortex

Easily add AI-generated fields to your Rails models.

## Motivation

ActiveCortex is born out of the need to easily integrate OpenAI into Rails.

Integrating with OpenAI is kind of a pain. It requires a lot of boilerplate: a
service object, dealing with OpenAI errors, defining custom functions, etc.
Also, OpenAI is constantly releasing new features, and keeping up-to-date is a
hassle.

Many developers aren't following OpenAI's best practices because they don't
have the time to develop the functionality required to follow them. For
example, it's a best practice to split complicated tasks into multiple prompts,
but some developers will avoid doing that to simplify their implementation.
This results in worse outputs. What if you could effortlessly write multi-stage
prompts and debug their performance?

We often write custom functions defining how to create a model we already have
a schema for! What if you could tell ChatGPT to provide its response in a
format that matches an ActiveRecord class?

Finally, we have to consider errors. OpenAI has downtime, sometimes returns
server errors, and ChatGPT sometimes bugs out and returns "Sorry, I can't help
you with that". What if you could remove the error handling logic from your
system?

ActiveCortex cleans up Rails codebases by providing a macro that deals with the
interface to OpenAI. (I'm still working on the above features, but that's the
vision for this gem!)

## Usage

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  include ActiveCortex::Model

  ai_generated :summary, prompt: -> (doc) { "Summarize: #{doc.text}" }
  # (or)
  ai_generated :summary, prompt: :generate_summary_prompt

  private

  def generate_summary_prompt
     "Summarize: #{text}"
  end
end

# ... then ...
doc = Document.new(text: "Call me Ishmael...")
doc.generate_summary!
doc.summary # => an AI-generated summary of `text`
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_cortex"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install active_cortex
```

And set an OpenAI key

```ruby
# config/initializers/active_cortex.rb
ActiveCortex.config.openai_key = ENV.fetch("OPENAI_ACCESS_TOKEN")
```

## Contributing

Happy for you to open an issue if you have ideas to improve the gem.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
