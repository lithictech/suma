# frozen_string_literal: true

module Suma::Mobility::Gbfs::Geo
  def self.simple_multipolygon(polyring)
    # multipoly is [][][][]
    # x/y, polyring, holes, multipoly
    return [[polyring]]
  end
end
