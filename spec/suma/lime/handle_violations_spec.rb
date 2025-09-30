# frozen_string_literal: true

require "suma/lime/handle_violations"

RSpec.describe Suma::Lime::HandleViolations, :db do
  before(:each) do
    described_class.new.row_iterator.reset
  end

  # rubocop:disable Layout/LineLength
  it "creates support tickets and attachments for violation messages" do
    now = Time.parse("2024-08-27T23:13:09+00:00")
    member = Suma::Fixtures.member.create(name: "Joleen Klocko", phone: "12375589839")
    mc = Suma::Fixtures.anon_proxy_member_contact.email("test@example.com").create(member:)

    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "service-violation",
      from_email: "support@limebike.com",
      to_email: mc.email,
      subject: "Service Violation Notification",
      timestamp: now,
      data: Sequel.pg_jsonb({"HtmlBody" => "service html", "TextBody" => "service-violation body"}),
    )
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "parking-violation",
      from_email: "no-reply@li.me",
      to_email: "NOEXIST@example.com",
      subject: "Parking violation",
      timestamp: now,
      data: Sequel.pg_jsonb({"HtmlBody" => "parking html", "TextBody" => "parking-violation body"}),
    )
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "old",
      from_email: "no-reply@li.me",
      to_email: mc.email,
      subject: "Parking violation",
      timestamp: now - 4.weeks,
      data: Sequel.pg_jsonb({}),
    )
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "bad-subject",
      from_email: "no-reply@li.me",
      to_email: mc.email,
      subject: "Not an expected subject",
      timestamp: now,
      data: Sequel.pg_jsonb({}),
    )

    Timecop.travel(now) do
      described_class.new.run
    end

    tickets = Suma::Support::Ticket.order(:subject).all
    expect(tickets).to contain_exactly(
      have_attributes(
        subject: "Service Violation Notification",
        body: "Anonymous email: test@example.com\nMember #{member.id}: Joleen Klocko, (237) 558-9839\nhttp://localhost:22014/member/#{member.id}\nOriginally sent by Lime: 2024-08-27T23:13:09+00:00\n\n\nservice-violation body",
      ),
      have_attributes(
        subject: "Parking violation",
        body: "Anonymous email: NOEXIST@example.com\nOriginally sent by Lime: 2024-08-27T23:13:09+00:00\n\n\nparking-violation body",
      ),
    )
    expect(tickets[0].uploaded_files.first).to have_attributes(
      content_type: "text/html",
      filename: "limewarning.html",
      read_blob_for_testing: "parking html",
    )
    expect(tickets[1].uploaded_files.first).to have_attributes(
      content_type: "text/html",
      filename: "limewarning.html",
      read_blob_for_testing: "service html",
    )
    # rubocop:enable Layout/LineLength
  end

  it "is idempotent for violations" do
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "msg1",
      from_email: "no-reply@li.me",
      to_email: "m1@example.com",
      subject: "Parking violation",
      timestamp: Time.now,
      data: Sequel.pg_jsonb({"HtmlBody" => "parking html", "TextBody" => "parking-violation body"}),
    )

    described_class.new.run
    expect(Suma::Support::Ticket.all).to contain_exactly(have_attributes(external_id: "msg1"))
    described_class.new.row_iterator.reset
    described_class.new.run
    expect(Suma::Support::Ticket.all).to contain_exactly(have_attributes(external_id: "msg1"))
  end
end
