# frozen_string_literal: true

require "suma/postgres/model"

require "suma/message"

class Suma::Message::Body < Suma::Postgres::Model(:message_bodies)
  plugin :timestamps

  many_to_one :delivery, class: "Suma::Message::Delivery"
end
