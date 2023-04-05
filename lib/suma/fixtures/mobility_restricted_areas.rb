# frozen_string_literal: true

require "suma/fixtures"
require "suma/mobility/restricted_area"

module Suma::Fixtures::MobilityRestrictedAreas
  extend Suma::Fixtures

  fixtured_class Suma::Mobility::RestrictedArea

  base :mobility_restricted_area do
    self.unique_id ||= Faker::Address.street_address
    self.title ||= self.unique_id
    self.restriction ||= Suma::Mobility::RestrictedArea::RESTRICTIONS.sample
    self.multipolygon ||= Suma::Mobility::Gbfs::Geo.simple_multipolygon(
      # Right triangle
      [
        [0, 0],
        [10, 0], # top
        [10, 0], # right
        [0, 0],
      ],
    )
  end

  decorator :diamond do |x:, y:, w:, h:|
    hw = w * 0.5
    hh = h * 0.5
    self.multipolygon = Suma::Mobility::Gbfs::Geo.simple_multipolygon(
      [
        [y + hh, x], # left corner: x,y -> y,x due to lat/lng
        [y + h, x + hw], # top
        [y + hh, x + w], # right
        [y, x + hw], # bottom
        [y + hh, x], # we use matching first/last for closed polygons
      ],
    )
  end

  decorator :latlng_bounds do |sw:, ne:|
    self.multipolygon = Suma::Mobility::Gbfs::Geo(
      [
        [sw[0], sw[1]], # SW
        [ne[0], sw[1]], # NW
        [ne[0], ne[1]], # NE
        [sw[0], ne[1]], # SE
        [sw[0], sw[1]], # SW
      ],
    )
  end
end
