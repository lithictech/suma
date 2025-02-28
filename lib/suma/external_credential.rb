# frozen_string_literal: true

require "suma/postgres/model"

# Represents dynamic credentials used to access some external system.
# Usually this would be something like an oauth token.
class Suma::ExternalCredential < Suma::Postgres::Model(:external_credentials)
  plugin :insert_conflict
  plugin :column_encryption do |enc|
    enc.column :data
  end
end
