require "json"
require "pathname"

module Mew
  module Frontmatter
    FRONTMATTER_ORDER = %w[name type criticality scope keywords
                           provenance hits last_used created].freeze

    SCALAR_QUOTE_CHARS = ",-:#[]{}\"'\n\r\t".freeze

    def self.unscalar(text)
      text = text.strip
      if text.length >= 2 && text[0] == '"' && text[-1] == '"'
        begin
          return JSON.parse(text)
        rescue JSON::ParserError
          return text[1..-2]
        end
      end
      text
    end

    def self.scalar(value)
      return value ? "true" : "false" if value == true || value == false
      return '""' if value.nil?
      return value.to_s if value.is_a?(Integer)

      text = value.to_s
      needs_quotes = text.empty? || text != text.strip ||
                     text.each_char.any? { |c| SCALAR_QUOTE_CHARS.include?(c) }
      needs_quotes ? JSON.generate(text, ascii_only: true) : text
    end

    def self.emit(cand)
      out = ["---"]
      FRONTMATTER_ORDER.each do |key|
        if key == "provenance"
          out << "provenance:"
          (cand["provenance"] || []).each do |entry|
            first = true
            entry.each do |ekey, evalue|
              prefix = first ? "  - " : "    "
              out << "#{prefix}#{ekey}: #{scalar(evalue)}"
              first = false
            end
          end
          next
        end
        if key == "scope" || key == "keywords"
          items = (cand[key] || []).map { |v| scalar(v) }.join(", ")
          out << "#{key}: [#{items}]"
          next
        end
        if key == "hits"
          hits_val = cand["hits"] || 0
          out << "hits: #{hits_val.is_a?(String) ? Integer(hits_val, 10) : Integer(hits_val)}"
          next
        end
        out << "#{key}: #{scalar(cand.fetch(key, ""))}"
      end
      out << "---"
      out.join("\n")
    end

    def self.split_inline_list(raw)
      items = []
      buf = []
      in_quotes = false
      escaped = false
      raw.each_char do |ch|
        if escaped
          buf << ch
          escaped = false
        elsif ch == "\\"
          buf << ch
          escaped = true
        elsif ch == '"'
          in_quotes = !in_quotes
          buf << ch
        elsif ch == "," && !in_quotes
          items << buf.join
          buf = []
        else
          buf << ch
        end
      end
      items << buf.join
      items.map(&:strip).reject(&:empty?)
    end

    def self.relative_to_root(path)
      root = ENV["MB_ROOT"] && !ENV["MB_ROOT"].empty? ?
        Pathname.new(ENV["MB_ROOT"]) :
        Pathname.new(File.expand_path("../..", __dir__))
      Pathname.new(path.to_s).expand_path.relative_path_from(root.expand_path).to_s
    rescue StandardError
      path.to_s
    end

    def self.split_note(path)
      lines = File.read(path.to_s).each_line.to_a
      if lines.empty? || lines[0].strip != "---"
        return ["", lines.join]
      end
      (1...lines.length).each do |i|
        return [lines[0..i].join, lines[(i + 1)..-1].join] if lines[i].strip == "---"
      end
      [lines.join, ""]
    end

    def self.read_note_doc(path)
      frontmatter, body = split_note(path)
      doc = {
        "path" => relative_to_root(path),
        "body" => body.sub(/\A\n+/, "").sub(/\n+\z/, ""),
        "provenance" => [],
      }
      current = nil
      frontmatter.each_line(chomp: true) do |line|
        next if line == "---" || line == ""

        if line.start_with?("  - ") || line.start_with?("    ")
          key_value = line.strip.sub(/\A[- ]+/, "")
          key, _, value = key_value.partition(":")
          if key == "kind"
            current = {"kind" => unscalar(value)}
            doc["provenance"] << current
          elsif !current.nil?
            current[key] = unscalar(value)
          end
          next
        end

        key, _, value = line.partition(":")
        next if key == "provenance"

        if key == "scope" || key == "keywords"
          raw = value.strip.sub(/\A\[+/, "").sub(/\]+\z/, "")
          doc[key] = raw.empty? ? [] : split_inline_list(raw).map { |v| unscalar(v) }
        elsif key == "hits"
          parsed = unscalar(value).to_s
          doc[key] = parsed.empty? ? 0 : Integer(parsed, 10)
        else
          doc[key] = unscalar(value)
        end
      end
      doc
    end
  end
end
