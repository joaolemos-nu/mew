require "spec_helper"
require "mew/schema"

describe "Mew::Schema" do
  describe ".validate_candidate" do
    describe "accepts a fully valid candidate" do
      it "returns an empty error array" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [
            {
              "kind" => "doc",
              "ref" => "test-ref",
              "retrieved" => "2026-01-01"
            }
          ],
          "created" => "2026-01-01",
          "hits" => 0,
          "last_used" => ""
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to eq([])
      end
    end

    describe "returns the same error strings in the same order as the megabrain golden" do
      it "rejects a candidate missing keywords" do
        candidate = {
          "name" => "capture-save-error",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to eq(["keywords: required field missing"])
      end

      it "rejects a candidate with invalid type" do
        candidate = {
          "name" => "test-note",
          "type" => "not-a-real-type",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("type: must be one of ('finding', 'pattern', 'contract', 'gotcha', 'decision', 'route'), got not-a-real-type")
      end

      it "rejects a candidate with empty name" do
        candidate = {
          "name" => "",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("name: required field missing or empty")
      end

      it "rejects a candidate missing name" do
        candidate = {
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("name: required field missing or empty")
      end

      it "rejects a candidate with a name that is too long" do
        long_name = "a" * 121
        candidate = {
          "name" => long_name,
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("name: must be at most 120 bytes — it becomes a filename")
      end

      it "rejects a candidate with invalid filename characters in name" do
        candidate = {
          "name" => "test/note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("name: must be a bare slug — no '/', '\\', '..' or leading dot (it becomes the note filename)")
      end

      it "rejects a candidate with invalid criticality" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "invalid",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("criticality: must be one of ('critical', 'normal'), got invalid")
      end

      it "rejects a candidate missing scope" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("scope: required field missing")
      end

      it "rejects a candidate with scope as a string instead of a list" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => "acme",
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("scope: must be a list of strings, got str")
      end

      it "rejects a candidate with empty keywords list" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => [],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("keywords: must not be empty")
      end

      it "rejects a candidate with invalid hits (negative)" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01",
          "hits" => -1
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("hits: must be an integer >= 0")
      end

      it "rejects a candidate with invalid created date" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "invalid-date"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("created: must be a real ISO date YYYY-MM-DD (it becomes part of the filename and is parsed by later consumers)")
      end

      it "rejects a candidate missing created" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }]
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("created: required field missing or empty")
      end

      it "rejects a candidate missing provenance" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("provenance: at least one entry required")
      end

      it "rejects a candidate with provenance missing kind" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "ref" => "test-ref" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("provenance: each entry must have a 'kind' field")
      end

      it "rejects a candidate with provenance missing ref" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "doc" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("provenance: each entry must have a 'ref' field")
      end

      it "rejects a candidate with invalid provenance kind" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "invalid-kind", "ref" => "test-ref" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("provenance: unknown kind 'invalid-kind'")
      end

      it "rejects a candidate with doc provenance missing retrieved" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "doc", "ref" => "test-ref" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("provenance: kind 'doc' requires a 'retrieved' field")
      end

      it "rejects a candidate with sdd provenance missing anchor" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "sdd", "ref" => "test-ref" }],
          "created" => "2026-01-01"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("provenance: kind 'sdd' requires an 'anchor' naming the source heading")
      end
    end

    describe "rejects a loose date" do
      it "rejects a non-zero-padded date in created field" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-1-1"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).not_to be_empty
        expect(errors).to include("created: must be a real ISO date YYYY-MM-DD (it becomes part of the filename and is parsed by later consumers)")
      end

      it "rejects a non-zero-padded date in last_used field" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01",
          "last_used" => "2026-1-1"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("last_used: must be an ISO date YYYY-MM-DD or an empty string")
      end

      it "accepts valid ISO dates with zero padding" do
        candidate = {
          "name" => "test-note",
          "type" => "finding",
          "criticality" => "normal",
          "scope" => ["acme"],
          "keywords" => ["test"],
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
          "created" => "2026-01-01",
          "last_used" => "2026-01-05"
        }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to eq([])
      end
    end

    describe "byte-exactness cases found by B-core's review gate" do
      def base_candidate
        {
          "name" => "test-note", "type" => "finding", "criticality" => "normal",
          "scope" => ["acme"], "keywords" => ["test"], "created" => "2026-01-01",
          "provenance" => [{ "kind" => "session", "ref" => "cli-curated" }],
        }
      end

      it "renders a missing type as None, matching Python's f-string" do
        candidate = base_candidate.reject { |k, _| k == "type" }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("type: must be one of ('finding', 'pattern', 'contract', 'gotcha', 'decision', 'route'), got None")
      end

      it "renders a missing criticality as None, matching Python's f-string" do
        candidate = base_candidate.reject { |k, _| k == "criticality" }
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("criticality: must be one of ('critical', 'normal'), got None")
      end

      it "rejects a reduced-precision created date that Date.iso8601 would accept" do
        candidate = base_candidate.merge("created" => "2026-01")
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("created: must be a real ISO date YYYY-MM-DD (it becomes part of the filename and is parsed by later consumers)")
      end

      it "rejects a created datetime that Date.iso8601 would accept" do
        candidate = base_candidate.merge("created" => "2026-01-01T10:00:00")
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("created: must be a real ISO date YYYY-MM-DD (it becomes part of the filename and is parsed by later consumers)")
      end

      it "accepts a whitespace-only name, matching Python's truthy-string check" do
        candidate = base_candidate.merge("name" => "   ")
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to eq([])
      end

      it "rejects a non-string falsy name (0), matching Python's `if not name`" do
        candidate = base_candidate.merge("name" => 0)
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("name: required field missing or empty")
      end

      it "rejects a whitespace-only last_used, since it is truthy but not a valid date" do
        candidate = base_candidate.merge("last_used" => "  ")
        errors = Mew::Schema.validate_candidate(candidate)
        expect(errors).to include("last_used: must be an ISO date YYYY-MM-DD or an empty string")
      end
    end
  end

  describe "constants" do
    it "exports NOTE_TYPES as a frozen array" do
      expect(Mew::Schema::NOTE_TYPES).to eq(["finding", "pattern", "contract", "gotcha", "decision", "route"])
      expect(Mew::Schema::NOTE_TYPES.frozen?).to be(true)
    end

    it "exports CRITICALITIES as a frozen array" do
      expect(Mew::Schema::CRITICALITIES).to eq(["critical", "normal"])
      expect(Mew::Schema::CRITICALITIES.frozen?).to be(true)
    end

    it "exports PROVENANCE_KINDS as a frozen array" do
      expect(Mew::Schema::PROVENANCE_KINDS).to eq(["doc", "pr", "ticket", "slack", "code", "sdd", "dashboard", "session"])
      expect(Mew::Schema::PROVENANCE_KINDS.frozen?).to be(true)
    end
  end
end
