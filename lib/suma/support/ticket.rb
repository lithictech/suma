# frozen_string_literal: true

require "suma/postgres/model"
require "suma/support"

class Suma::Support::Ticket < Suma::Postgres::Model(:support_tickets)
  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  many_to_many :uploaded_files,
               class: "Suma::UploadedFile",
               join_table: :support_tickets_uploaded_files,
               left_key: :support_ticket_id,
               order: order_desc
end
