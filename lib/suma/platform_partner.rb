# frozen_string_literal: true

require "suma/postgres/model"

class Suma::PlatformPartner < Suma::Postgres::Model(:platform_partners)
  plugin :timestamps

  def before_create
    self.short_slug ||= Suma.to_slug(self.name)
  end
end
