require 'spec_helper'
require 'mew'

describe Mew do
  it 'loads standalone with no megabrain checkout on the load path and asserts the version constant' do
    expect(Mew::VERSION).to eq('0.1.0')
  end

  it 'declares no runtime dependencies' do
    gemspec_path = File.expand_path('../../mew.gemspec', __FILE__)
    spec = Gem::Specification.load(gemspec_path)

    runtime_deps = spec.runtime_dependencies.map(&:name)
    expect(runtime_deps.empty?).to be true
  end
end
