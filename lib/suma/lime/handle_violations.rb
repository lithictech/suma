# frozen_string_literal: true

class Suma::Lime::HandleViolations
  LAST_SYNCED_PK_KEY = "lime/handleviolations/pk"
  CUTOFF = 2.weeks

  def run
    last_synced_pk = Suma::Redis.cache.with { |c| c.call("GET", LAST_SYNCED_PK_KEY) }.to_i
    rows = Suma::Webhookdb.postmark_inbound_messages_dataset.
      where(from_email: ["support@limebike.com", "no-reply@li.me"]).
      where(Sequel.ilike(:subject, "%Service Violation Notification%") | Sequel.ilike(:subject, "%Parking violation%")).
      where { pk > last_synced_pk }.
      where { timestamp > CUTOFF.ago }.
      order(:pk).
      all
    return 0 if rows.empty?
    rows.each do |row|
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
        comment: {
          body: body_lines.join("\n"),
          attachments: ["data:text/html;name=limewarning.html;base64,#{Base64.strict_encode64(html_body)}"],
        },
      )
    end
    Suma::Redis.cache.with { |c| c.call("SET", LAST_SYNCED_PK_KEY, rows.last.fetch(:pk).to_s) }
    return rows.size
  end
end
