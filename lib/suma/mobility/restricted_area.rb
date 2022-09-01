# frozen_string_literal: true

require "suma/mobility"
require "suma/postgres/model"

class Suma::Mobility::RestrictedArea < Suma::Postgres::Model(:mobility_restricted_areas)
  plugin :timestamps

  RESTRICTIONS = [
    "do-not-park",
    "do-not-ride",
    "do-not-park-or-ride",
  ].freeze

  dataset_module do
    def intersecting(ne:, sw:)
      nelat, nelng = ne
      swlat, swlng = sw
      contains_ne = Sequel.expr { (ne_lat <= nelat) & (ne_lat >= swlat) & (ne_lng <= nelng) & (ne_lng >= swlng) }
      contains_sw = Sequel.expr { (sw_lat <= nelat) & (sw_lat >= swlat) & (sw_lng <= nelng) & (sw_lng >= swlng) }
      return self.where(contains_ne | contains_sw)
    end
  end

  def bounds
    return {
      ne: [self.ne_lat, self.ne_lng],
      sw: [self.sw_lat, self.sw_lng],
    }
  end

  def bounds_numeric
    return {
      ne: [self.ne_lat.to_f, self.ne_lng.to_f],
      sw: [self.sw_lat.to_f, self.sw_lng.to_f],
    }
  end

  def polygon_numeric
    return self.polygon.map do |c|
      c.map(&:to_f)
    end
  end

  def before_save
    if self.polygon.present?
      lats, lngs = self.polygon.transpose
      self.sw_lat, self.ne_lat = lats.minmax
      self.sw_lng, self.ne_lng = lngs.minmax
    end
    super
  end

  def validate
    super
    if self.polygon.nil?
      self.validates_not_null(:polygon)
    elsif self.polygon.length < 4
      self.errors.add(:polygon, "requires at least 4 coordinates (closed triangle)")
    elsif self.polygon.first != self.polygon.last
      self.errors.add(:polygon, "first and last coordinate must match (closed polygon)")
    end
  end
end