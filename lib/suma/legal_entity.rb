# frozen_string_literal: true

require "suma/postgres/model"

class Suma::LegalEntity < Suma::Postgres::Model(:legal_entities)
  many_to_one :address, class: "Suma::Address"
  one_to_one :customer, class: "Suma::Customer"

  class Display
    attr_reader :legal_entity, :id, :name, :address

    def initialize(legal_entity, name: nil, address: nil)
      @legal_entity = legal_entity
      @id = @legal_entity.id
      @name = @legal_entity.name
      @address = @legal_entity.address
      @name = name if name
      @address = address if address
    end
  end
end
