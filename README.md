# ActiveCortex

Easily add AI-generated fields to your Rails models.

## Usage

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  include ActiveCortex::Model

  ai_generated :summary, prompt: -> (doc) { "Summarize: #{doc.text}" }
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
