# frozen_string_literal: true

require "json"

module Wokku
  module Output
    module_function

    def table(rows, headers: nil)
      return if rows.empty?
      cols = (headers || rows.first.keys).map(&:to_s)
      widths = cols.map(&:length)
      rows.each { |r| cols.each_with_index { |c, i| widths[i] = [widths[i], r[c].to_s.length].max } }

      fmt = widths.map { |w| "%-#{w}s" }.join("  ")
      puts fmt % cols.map(&:upcase)
      puts widths.map { |w| "-" * w }.join("  ")
      rows.each { |r| puts fmt % cols.map { |c| r[c] } }
    end

    def puts_json(data)
      puts JSON.pretty_generate(data)
    end
  end
end
