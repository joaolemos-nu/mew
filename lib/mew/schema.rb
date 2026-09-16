require "date"

module Mew
  module Schema
    NOTE_TYPES = ["finding", "pattern", "contract", "gotcha", "decision", "route"].freeze
    CRITICALITIES = ["critical", "normal"].freeze
    PROVENANCE_KINDS = ["doc", "pr", "ticket", "slack", "code", "sdd", "dashboard", "session"].freeze

    # Python's `if not x` truthiness: nil, false, "", 0, 0.0, and empty collections are falsy;
    # everything else (including whitespace-only strings and non-empty non-string values) is
    # truthy. Ruby's `!x` only treats nil/false as falsy, so callers that need Python's exact
    # truthiness (not just Ruby's) must go through this.
    def self.py_falsy?(val)
      return true if val.nil? || val == false
      return true if (val.is_a?(String) || val.is_a?(Numeric)) && (val == "" || val == 0)
      return true if val.respond_to?(:empty?) && val.empty?
      false
    end

    # Python's str(x) for the handful of value shapes that show up in an f-string here:
    # None -> "None", True/False -> "True"/"False", everything else -> to_s.
    def self.py_str(val)
      return "None" if val.nil?
      return "True" if val == true
      return "False" if val == false
      val.to_s
    end

    # Python's `datetime.date.fromisoformat` (3.11+) accepts exactly: a complete calendar date
    # in extended ("YYYY-MM-DD") or basic ("YYYYMMDD") form, or a complete ISO week date in
    # extended ("YYYY-Www-D") or basic ("YYYYWwwD") form. It rejects reduced precision
    # ("YYYY-MM"), any time component, and a leading sign on the year. `Date.iso8601` alone is
    # far more permissive than this (it accepts all of those Python rejects), so the shape has
    # to be gated by regex first and only a matching shape handed to Ruby's date parser.
    ISO_CALENDAR_RE = /\A\d{8}\z|\A\d{4}-\d{2}-\d{2}\z/
    ISO_WEEK_RE = /\A\d{4}-?W\d{2}-?\d\z/

    def self.valid_iso_date?(val)
      return false unless val.is_a?(String)
      return false unless val.match?(ISO_CALENDAR_RE) || val.match?(ISO_WEEK_RE)
      begin
        Date.iso8601(val)
        true
      rescue ArgumentError
        false
      end
    end

    def self.validate_candidate(cand)
      errs = []

      name = cand["name"]
      if py_falsy?(name)
        errs.append("name: required field missing or empty")
      elsif name.to_s.bytesize > 120
        errs.append("name: must be at most 120 bytes — it becomes a filename")
      elsif ["/", "\\", ".."].any? { |part| name.to_s.include?(part) } || name.to_s.start_with?(".")
        errs.append("name: must be a bare slug — no '/', '\\', '..' or leading dot (it becomes the note filename)")
      end

      unless NOTE_TYPES.include?(cand["type"])
        type_list = "(" + NOTE_TYPES.map { |t| "'#{t}'" }.join(", ") + ")"
        errs.append("type: must be one of #{type_list}, got #{py_str(cand["type"])}")
      end

      unless CRITICALITIES.include?(cand["criticality"])
        crit_list = "(" + CRITICALITIES.map { |c| "'#{c}'" }.join(", ") + ")"
        errs.append("criticality: must be one of #{crit_list}, got #{py_str(cand["criticality"])}")
      end

      unless cand.key?("scope")
        errs.append("scope: required field missing")
      else
        errs.concat(list_of_strings_errors("scope", cand["scope"]))
      end

      unless cand.key?("keywords")
        errs.append("keywords: required field missing")
      else
        errs.concat(list_of_strings_errors("keywords", cand["keywords"]))
        if cand["keywords"].is_a?(Array) && cand["keywords"].empty?
          errs.append("keywords: must not be empty")
        end
      end

      if cand.key?("hits")
        hits = cand["hits"]
        if hits.is_a?(TrueClass) || hits.is_a?(FalseClass) || !hits.is_a?(Integer) || hits < 0
          errs.append("hits: must be an integer >= 0")
        end
      end

      last_used = cand.fetch("last_used", "")
      unless py_falsy?(last_used)
        unless valid_iso_date?(last_used.to_s)
          errs.append("last_used: must be an ISO date YYYY-MM-DD or an empty string")
        end
      end

      if !cand.key?("created") || py_falsy?(cand["created"])
        errs.append("created: required field missing or empty")
      else
        unless valid_iso_date?(cand["created"].to_s)
          errs.append("created: must be a real ISO date YYYY-MM-DD (it becomes part of the filename and is parsed by later consumers)")
        end
      end

      provenance = cand["provenance"] || []
      if py_falsy?(provenance) || (provenance.respond_to?(:length) && provenance.length == 0)
        errs.append("provenance: at least one entry required")
      else
        provenance.each do |entry|
          unless entry.is_a?(Hash)
            # Python duck-types here (`"kind" not in entry`, iteration over whatever `provenance`
            # is) rather than type-checking `entry`; a non-Hash entry has neither key, so treat
            # it as missing both required fields instead of silently skipping it.
            errs.append("provenance: each entry must have a 'kind' field")
            errs.append("provenance: each entry must have a 'ref' field")
            next
          end

          unless entry.key?("kind")
            errs.append("provenance: each entry must have a 'kind' field")
          end

          if entry.key?("kind") && !PROVENANCE_KINDS.include?(entry["kind"])
            errs.append("provenance: unknown kind '#{entry["kind"]}'")
          end

          unless entry.key?("ref")
            errs.append("provenance: each entry must have a 'ref' field")
          end

          if entry.fetch("kind", nil) && ["doc", "slack", "dashboard"].include?(entry["kind"])
            unless entry.key?("retrieved")
              errs.append("provenance: kind '#{entry["kind"]}' requires a 'retrieved' field")
            end
          end

          if entry.fetch("kind", nil) == "sdd" && !entry.fetch("anchor", nil)
            errs.append("provenance: kind 'sdd' requires an 'anchor' naming the source heading")
          end
        end
      end

      errs
    end

    def self.list_of_strings_errors(field, value)
      errs = []

      if value.is_a?(String) || !value.is_a?(Array)
        type_name = case value.class.name
                    when "String" then "str"
                    when "Array" then "list"
                    when "Hash" then "dict"
                    when "Integer" then "int"
                    when "Float" then "float"
                    when "TrueClass" then "bool"
                    when "FalseClass" then "bool"
                    when "NilClass" then "NoneType"
                    else value.class.name
                    end
        errs.append("#{field}: must be a list of strings, got #{type_name}")
      elsif value.any? { |item| !item.is_a?(String) || item.strip.empty? }
        errs.append("#{field}: every entry must be a non-empty string")
      end

      errs
    end
  end
end
