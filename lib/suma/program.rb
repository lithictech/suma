# frozen_string_literal: true

require "suma/admin_linked"
require "suma/image"
require "suma/postgres/model"

class Suma::Program < Suma::Postgres::Model(:programs)
  include Suma::AdminLinked
  include Suma::Image::AssociatedMixin

  plugin :timestamps
  plugin :tstzrange_fields, :period
  plugin :translated_text, :name, Suma::TranslatedText
  plugin :translated_text, :description, Suma::TranslatedText

  dataset_module do
    def active(now: Time.now)
      return self.where { (lower(period) < now) & (upper(period) > now) }
    end
  end

  def utility? = self.is_utility
end
