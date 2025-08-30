# frozen_string_literal: true

require "suma/lime/handle_violations"

RSpec.describe Suma::Lime::HandleViolations, :db do
  before(:each) do
    Suma::Webhookdb.postmark_inbound_messages_dataset.delete
    described_class.new.row_iterator.reset
  end

  it "creates Front discussion conversations for violation messages" do
    now = Time.parse("2024-08-27T23:13:09+00:00")
    member = Suma::Fixtures.member.create(name: "Joleen Klocko", phone: "12375589839")
    mc = Suma::Fixtures.anon_proxy_member_contact.email("test@example.com").create(member:)

    # rubocop:disable Layout/LineLength
    req = stub_request(:post, "https://api2.frontapp.com/conversations").
      with do |req|
      expect(req.body).to include("Content-Disposition: form-data; name=\"type\"\r\n\r\ndiscussion")
      expect(req.body).to include("name=\"inbox_id\"\r\n\r\ninb_123")
      if req.body.include?("Service Violation")
        expect(req.body).to include("name=\"subject\"\r\n\r\nService Violation Notification")
        expect(req.body).to include("name=\"comment[body]\"\r\n\r\nAnonymous email: test@example.com\nMember #{member.id}: Joleen Klocko, (237) 558-9839\nhttp://localhost:22014/member/#{member.id}\nOriginally sent by Lime: 2024-08-27T23:13:09+00:00\n\n\ntxtbody")
      else
        expect(req.body).to include("name=\"subject\"\r\n\r\nParking violation")
        expect(req.body).to include("name=\"comment[body]\"\r\n\r\nAnonymous email: nonexist@in.mysuma.org\nOriginally sent by Lime: 2024-08-27T23:13:09+00:00\n\n\ntxtbody")
      end
      expect(req.body).to include("name=\"attachments[0]\"; filename=\"limewarning.html\"\r\nContent-Type: text/html\r\n\r\nhtmlbody")
    end.to_return(json_response({}), json_response({}))
    # rubocop:enable Layout/LineLength

    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "valid-to-email",
      from_email: "support@limebike.com",
      to_email: mc.email,
      subject: "Service Violation Notification",
      timestamp: now,
      data: Sequel.pg_jsonb({"HtmlBody" => "htmlbody", "TextBody" => "txtbody"}),
    )
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "invalid-to-email",
      from_email: "no-reply@li.me",
      to_email: "nonexist@in.mysuma.org",
      subject: "Parking violation",
      timestamp: now,
      data: Sequel.pg_jsonb({"HtmlBody" => "htmlbody", "TextBody" => "txtbody"}),
    )
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "old",
      from_email: "no-reply@li.me",
      to_email: "nonexist@in.mysuma.org",
      subject: "Parking violation",
      timestamp: now - 4.weeks,
      data: Sequel.pg_jsonb({}),
    )
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "bad-subject",
      from_email: "no-reply@li.me",
      to_email: "nonexist@in.mysuma.org",
      subject: "Not an expected subject",
      timestamp: now,
      data: Sequel.pg_jsonb({}),
    )

    Timecop.travel(now) do
      described_class.new.run
      expect(req).to have_been_made.times(2)

      # Ensure we keep track of what's been synced
      described_class.new.run
    end
  end
end
