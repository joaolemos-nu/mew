Gem::Specification.new do |spec|
  spec.name = 'mew'
  spec.version = '0.1.0'
  spec.authors = ['João Lemos']
  spec.email = ['jmarcusfernandes@gmail.com']

  spec.summary = 'The single implementation of João\'s personal note schema'
  spec.description = 'Mew is the shared gem implementing the note schema — frontmatter fields, validation rules, JSON and YAML serialization'
  spec.homepage = 'https://github.com/joaolemos-nu/mew'

  spec.required_ruby_version = '>= 4.0.7'

  spec.files = Dir.glob('lib/**/*.rb') + Dir.glob('spec/**/*.rb') + %w[README.md mew.gemspec]

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
end
