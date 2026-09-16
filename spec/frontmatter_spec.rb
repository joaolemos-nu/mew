require "spec_helper"

describe Mew::Frontmatter do
  describe "matches the copied golden byte for byte" do
    it "reproduces the simple frontmatter golden" do
      candidate = {
        "name" => "finding-cache-flush",
        "type" => "finding",
        "criticality" => "normal",
        "scope" => ["finn"],
        "keywords" => ["cache", "flush", "bdc"],
        "provenance" => [
          {
            "kind" => "doc",
            "ref" => "reference-bdc-cache-flush",
            "retrieved" => "2026-01-01"
          }
        ],
        "hits" => 3,
        "last_used" => "2026-01-05",
        "created" => "2026-01-01"
      }

      emitted = Mew::Frontmatter.emit(candidate)
      golden_path = File.join(__dir__, "fixtures", "frontmatter_simple.txt")
      golden = File.read(golden_path)

      expect(emitted).to eq(golden)
    end

    it "reproduces the non-ASCII frontmatter golden" do
      candidate = {
        "name" => "gotcha-non-ascii-cafe",
        "type" => "gotcha",
        "criticality" => "normal",
        "scope" => ["finn"],
        "keywords" => ["é", "café", "compilação"],
        "provenance" => [
          {
            "kind" => "code",
            "ref" => "bin/mb.py:1"
          }
        ],
        "hits" => 0,
        "last_used" => "",
        "created" => "2026-01-01"
      }

      emitted = Mew::Frontmatter.emit(candidate)
      golden_path = File.join(__dir__, "fixtures", "frontmatter_quoted_scalar.txt")
      golden = File.read(golden_path)

      expect(emitted).to eq(golden)
    end
  end

  describe "still un-quotes scalars on re-emission" do
    it "removes unnecessary quotes from scalars" do
      # A scalar that was unnecessarily quoted on disk, with unquoted on re-emission
      candidate = {
        "name" => "decision-quoted-scalar",
        "type" => "decision",
        "criticality" => "normal",
        "scope" => ["finn"],
        "keywords" => ["consumer lag", "billing"],
        "provenance" => [
          {
            "kind" => "sdd",
            "ref" => "plans/2026-01-01-x.md",
            "anchor" => "Decision log / D1"
          }
        ],
        "hits" => 0,
        "last_used" => "",
        "created" => "2026-01-01"
      }

      emitted = Mew::Frontmatter.emit(candidate)

      # The keywords should be emitted per the Python rules:
      # "consumer lag" contains no special chars in the Python check, so it's unquoted
      # "billing" also has no special chars, so it's unquoted
      lines = emitted.split("\n")
      keywords_line = lines.find { |line| line.start_with?("keywords:") }

      # Both should be unquoted (this is the observed lossy behavior)
      expect(keywords_line).to include("consumer lag")
      expect(keywords_line).to include("billing")
      expect(keywords_line).not_to include('"consumer lag"')
    end
  end

  describe "matches the three indent goldens and escapes non-ASCII" do
    before do
      @candidate = {
        "name" => "finding-cache-flush",
        "type" => "finding",
        "criticality" => "normal",
        "scope" => ["finn"],
        "keywords" => ["cache", "flush", "bdc"],
        "provenance" => [
          {
            "kind" => "doc",
            "ref" => "reference-bdc-cache-flush",
            "retrieved" => "2026-01-01"
          }
        ],
        "hits" => 3,
        "last_used" => "2026-01-05",
        "created" => "2026-01-01"
      }
    end

    it "reproduces compact JSON golden byte-for-byte" do
      emitted = Mew::JsonFmt.compact(@candidate)
      golden_path = File.join(__dir__, "fixtures", "json_compact.json")
      golden = File.read(golden_path).chomp

      expect(emitted).to eq(golden)
    end

    it "reproduces one-space indent JSON golden byte-for-byte" do
      emitted = Mew::JsonFmt.indent_1(@candidate)
      golden_path = File.join(__dir__, "fixtures", "json_indent_1.json")
      golden = File.read(golden_path).chomp

      expect(emitted).to eq(golden)
    end

    it "reproduces two-space indent JSON golden byte-for-byte" do
      emitted = Mew::JsonFmt.indent_2(@candidate)
      golden_path = File.join(__dir__, "fixtures", "json_indent_2.json")
      golden = File.read(golden_path).chomp

      expect(emitted).to eq(golden)
    end

    it "escapes non-ASCII characters in JSON output" do
      candidate_with_unicode = {
        "name" => "gotcha-cafe",
        "type" => "gotcha",
        "criticality" => "normal",
        "scope" => ["finn"],
        "keywords" => ["café"],
        "provenance" => [{"kind" => "code", "ref" => "test:1"}],
        "hits" => 0,
        "last_used" => "",
        "created" => "2026-01-01"
      }

      emitted = Mew::JsonFmt.compact(candidate_with_unicode)

      # Should contain escaped Unicode, not raw UTF-8
      expect(emitted).to include("\\u00e9")
      expect(emitted).not_to include("é")
    end
  end
end
