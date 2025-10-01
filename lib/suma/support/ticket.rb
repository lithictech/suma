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

  def sync_to_front
    return if self.front_id
    params = {
      type: "discussion",
      inbox_id: Suma::Frontapp.to_inbox_id(Suma::Frontapp.default_inbox_id),
      subject: self.subject,
      "comment[body]" => self.body,
    }
    self.uploaded_files.each_with_index do |uf, i|
      params["attachments[#{i}]"] = HTTP::FormData::Part.new(
        uf.blob_stream_unsafe.read, content_type: uf.content_type, filename: uf.filename,
      )
    end
    resp = Suma::Frontapp.client.create_conversation(params)
    self.update(front_id: resp.fetch("id"))
    return resp
  end
end
