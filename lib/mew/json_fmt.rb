require "json"

module Mew
  module JsonFmt
    def self.indent_1(obj)
      escape_non_ascii(obj.to_json(indent: " ", space: " ", object_nl: "\n", array_nl: "\n"))
    end

    def self.indent_2(obj)
      escape_non_ascii(obj.to_json(indent: "  ", space: " ", object_nl: "\n", array_nl: "\n"))
    end

    def self.compact(obj)
      raw = obj.to_json(indent: "", space: " ", object_nl: "\n", array_nl: "\n")
      escape_non_ascii(raw.gsub(",\n", ", ").gsub("\n", ""))
    end

    def self.escape_non_ascii(str)
      str.each_char.map do |ch|
        codepoint = ch.ord
        next ch if codepoint < 128

        if codepoint > 0xFFFF
          codepoint -= 0x10000
          high = 0xD800 + (codepoint >> 10)
          low = 0xDC00 + (codepoint & 0x3FF)
          format("\\u%04x\\u%04x", high, low)
        else
          format("\\u%04x", codepoint)
        end
      end.join
    end

    private_class_method :escape_non_ascii
  end
end
