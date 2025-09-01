# frozen_string_literal: true

class Suma::Lime::HandleViolations
  CUTOFF = 2.weeks

  def row_iterator = Suma::Webhookdb::RowIterator.new("lime/handleviolations/pk")

  def run
    ds = Suma::Webhookdb.postmark_inbound_messages_dataset.
      where(from_email: ["support@limebike.com", "no-reply@li.me"]).
      where(Sequel.ilike(:subject, "%Service Violation Notification%") | Sequel.ilike(:subject, "%Parking violation%")).
      where { timestamp > CUTOFF.ago }
    num_synced = self.row_iterator.each(ds) do |row|
      member = Suma::AnonProxy::MemberContact[email: row.fetch(:to_email)]&.member
      html_body = row.fetch(:data).fetch("HtmlBody")
      body_lines = [
        "Anonymous email: #{row.fetch(:to_email)}",
        member && "Member #{member.id}: #{member.name}, #{member.us_phone}",
        member&.admin_link,
        "Originally sent by Lime: #{row.fetch(:timestamp).iso8601}",
        "\n",
        row.fetch(:data).fetch("TextBody"),
      ].compact

      Suma::Frontapp.client.create_conversation(
        type: "discussion",
        inbox_id: Suma::Frontapp.to_inbox_id(Suma::Frontapp.default_inbox_id),
        subject: row.fetch(:subject),
        "comment[body]" => body_lines.join("\n"),
        "attachments[0]" => HTTP::FormData::Part.new(
          html_body, content_type: "text/html", filename: "limewarning.html",
        ),
      )
    end
    return num_synced
  end
end
