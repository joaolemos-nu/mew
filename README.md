# Mew

Mew is the single implementation of João's personal note schema. It defines and validates frontmatter fields, serialization rules for JSON and YAML, and provides a unified interface for working with note structures.

Mew is consumed symmetrically by:
- **megabrain** — the personal knowledge store and CLI
- **sai** (optionally) — the personal work dashboard

Both consumers reference Mew as a path or git dependency, never published to RubyGems.

## Installation

Add Mew as a dependency in your Gemfile:

```ruby
gem 'mew', path: '../mew'  # or git: 'https://github.com/joaolemos-nu/mew.git'
```

## Usage

Mew provides schema validation and serialization utilities for note data:

```ruby
require 'mew'

# Access schema and serialization modules
Mew::Schema      # Note schema validator
Mew::Frontmatter # Frontmatter emitter and parser
```

## Development

```bash
bundle install
bundle exec rspec
```

## License

Personal use only.
