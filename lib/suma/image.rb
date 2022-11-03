# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Image < Suma::Postgres::Model(:images)
  plugin :timestamps
  plugin :soft_deletes

  many_to_one :commerce_product, class: "Suma::Commerce::Product"
  many_to_one :uploaded_file, class: "Suma::UploadedFile"
end
