# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor < Suma::Postgres::Model(:vendors)
  plugin :timestamps

  many_to_one :organization, key: :organization_id, class: "Suma::Organization"

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end
end
