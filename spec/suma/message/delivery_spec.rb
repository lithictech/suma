# frozen_string_literal: true

require "suma/messages/specs"

RSpec.describe "Suma::Message::Delivery", :db, :messaging do
  let(:described_class) { Suma::Message::Delivery }

  context "datasets" do
    it "has a dataset for unsent messages" do
      unsent = Suma::Fixtures.message_delivery.create
      sent = Suma::Fixtures.message_delivery.sent.create
      deleted = Suma::Fixtures.message_delivery.create(aborted_at: Time.now)

      expect(described_class.unsent.all).to contain_exactly(unsent)
    end

    it "has a dataset to messages to a member dataset or array, where they are the recipient or to address" do
      member = Suma::Fixtures.member.create
      to_member = Suma::Fixtures.message_delivery.with_recipient(member).create
      to_email = Suma::Fixtures.message_delivery.to(member.email).create
      Suma::Fixtures.message_delivery.with_recipient.create
      Suma::Fixtures.message_delivery.create

      expect(described_class.to_members([member]).all).to contain_exactly(to_email, to_member)
      expect(described_class.to_members(Suma::Member.where(id: member.id)).all).to contain_exactly(
        to_email, to_member,
      )
    end
  end

  describe "body_with_mediatype" do
    it "returns the first body with a given mediatype" do
      d = Suma::Fixtures.message_delivery.create
      subj = d.add_body(mediatype: "subject", content: "Subject")
      text = d.add_body(mediatype: "text", content: "plaintext")
      html = d.add_body(mediatype: "html", content: "<html>")
      expect(d.body_with_mediatype("text")).to be === text
      expect(d.body_with_mediatype("abc")).to be_nil
    end
  end

  describe "body_with_mediatype!" do
    it "raises if no body matches the given " do
      expect do
        Suma::Fixtures.message_delivery.create.body_with_mediatype!("abc")
      end.to raise_error(/has no body with mediatype/)
    end
  end

  describe "send" do
    it "does not deliver sent messages" do
      d = Suma::Fixtures.message_delivery.sent.create
      expect(d.send!).to be_nil
      expect(Suma::Message::FakeTransport.sent_deliveries).to be_empty
    end

    it "does not deliver aborted messages" do
      d = Suma::Fixtures.message_delivery.aborted.create
      expect(d.send!).to be_nil
      expect(Suma::Message::FakeTransport.sent_deliveries).to be_empty
    end

    it "sends messages through the configured transport" do
      d = Suma::Fixtures.message_delivery.create
      expect(d.send!).to be === d
      expect(Suma::Message::FakeTransport.sent_deliveries).to contain_exactly(d)
    end

    it "updates fields about the sending" do
      d = Suma::Fixtures.message_delivery.create
      expect(d.send!).to be === d
      expect(d).to have_attributes(
        sent_at: be_within(5).of(Time.now),
        transport_message_id: start_with("#{d.id}-"),
      )
    end

    it "aborts if undeliverable" do
      d = Suma::Fixtures.message_delivery.create
      Suma::Message::FakeTransport.disable_func = proc { true }
      expect(d.send!).to be === d
      expect(d).to have_attributes(sent_at: nil, transport_message_id: nil, aborted_at: be_within(5).of(Time.now))
    end
  end

  describe "fixtures" do
    let(:member) { Suma::Fixtures.member.create }

    it "can specify a recipient" do
      d = Suma::Fixtures.message_delivery.to("me@co.co").create
      expect(d).to have_attributes(transport_type: "fake", to: "me@co.co", recipient: nil)

      d = Suma::Fixtures.message_delivery.to(member).create
      expect(d).to have_attributes(transport_type: "fake", to: member.email, recipient: member)
    end

    it "can specify a transport" do
      d = Suma::Fixtures.message_delivery.via(:email).create
      expect(d).to have_attributes(transport_type: "email", to: "fixture-to")

      d = Suma::Fixtures.message_delivery(recipient: member).via(:email).create
      expect(d).to have_attributes(transport_type: "email", to: member.email, recipient: member)
    end

    it "can fixture an email with bodies" do
      d = Suma::Fixtures.message_delivery.email.create
      expect(d).to have_attributes(transport_type: "email", to: include("@"), recipient: nil)
      expect(d.bodies).to contain_exactly(
        have_attributes(mediatype: "subject"),
        have_attributes(mediatype: "text/plain"),
        have_attributes(mediatype: "text/html"),
      )

      d = Suma::Fixtures.message_delivery.to(member).email.create
      expect(d).to have_attributes(transport_type: "email", to: member.email, recipient: member)
    end

    it "can be marked sent" do
      expect(Suma::Fixtures.message_delivery.sent.create).to have_attributes(sent_at: be_within(5).of(Time.now))
    end
  end

  describe "lookup_template_class" do
    it "can find by name" do
      cls = described_class.lookup_template_class("Testers::WithField")
      expect(cls).to be(Suma::Messages::Testers::WithField)
    end

    it "can find by slug" do
      cls = described_class.lookup_template_class("testers::missing_field")
      expect(cls).to be(Suma::Messages::Testers::MissingField)
    end

    it "errors if it does not exist" do
      expect do
        described_class.lookup_template_class("NotExisting")
      end.to raise_error(Suma::Message::MissingTemplateError)
    end
  end

  describe "preview" do
    it "errors if rack env is not development" do
      expect do
        described_class.preview("Testers::Basic", rack_env: "test")
      end.to raise_error(/only preview in development/)
    end

    it "returns the delivery but rolls back changes" do
      member_count = Suma::Member.count

      delivery = described_class.preview("Testers::Basic", rack_env: "development")

      expect(delivery).to be_a(described_class)
      expect(Suma::Member.count).to eq(member_count)
      expect(Suma::Message::Delivery[id: delivery.id]).to be_nil
    end

    it "can commit changes" do
      member_count = Suma::Member.count

      delivery = described_class.preview("Testers::Basic", commit: true, rack_env: "development")

      expect(delivery).to be_a(described_class)
      expect(Suma::Member.count).to eq(member_count + 1)
      expect(Suma::Message::Delivery[id: delivery.id]).to be === delivery
    end
  end
end
