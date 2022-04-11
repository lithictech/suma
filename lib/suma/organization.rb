# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  plugin :timestamps

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end
end
