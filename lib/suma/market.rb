# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Market < Suma::Postgres::Model(:markets)
  plugin :timestamps

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end
end
