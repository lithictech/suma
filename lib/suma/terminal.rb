# frozen_string_literal: true

module Suma::Terminal
  # Return a table string for the given headers and rows.
  # Instead of adding features to this, use a 3rd party Gem,
  # but we have this simple thing for current needs.
  module_function def ascii_table(rows, headers: nil)
    all = headers ? ([headers] + rows) : rows
    widths = all.transpose.map { |c| c.map(&:length).max }
    sep = "+" + widths.map { |w| "-" * (w + 2) }.join("+") + "+"
    fmt = lambda { |row|
      "| " + row.each_with_index.map { |c, i|
        c.ljust(widths[i])
      }.join(" | ") + " |"
    }

    str_rows = [sep]
    if headers
      str_rows << fmt.call(headers)
      str_rows << sep
    end
    str_rows.concat(rows.map { |r| fmt.call(r) })
    str_rows << sep
    s = str_rows.join("\n")
    return s
  end
end
