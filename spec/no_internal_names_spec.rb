require "spec_helper"

# Mew is public. It must never carry a real Nubank-internal service name, team name, or
# acronym in its source, fixtures, or specs -- not because scope/keywords are schema-enumerated
# (they aren't, see lib/mew/schema.rb:71-74; scope is deliberately opaque), but because a
# fixture picking a REAL value for no reason is how "finn"/"bdc" leaked in the first place
# (caught by an external reviewer, not by this repo's own suite). Any real-name vocabulary, and
# any rule mapping an abstract fixture value back to a real one, belongs in megabrain (private),
# never here.
RSpec.describe "public-repo hygiene" do
  DENYLIST = %w[
    finn bdc nubank diplomat dashiki catalyst loterica trabalha sachem septima puerta
  ].freeze

  TRACKED_FILES = `git ls-files`.split("\n").freeze

  it "has tracked files to check" do
    expect(TRACKED_FILES).not_to be_empty
  end

  DENYLIST.each do |term|
    it "never mentions #{term.inspect} in any tracked file" do
      hits = TRACKED_FILES.select do |path|
        File.file?(path) && File.read(path).downcase.include?(term)
      end
      expect(hits).to eq([]), "found #{term.inspect} in: #{hits.join(', ')}"
    end
  end
end
