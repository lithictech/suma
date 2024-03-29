# frozen_string_literal: true

RSpec.describe "Suma::Member::ResetCode", :db do
  let(:described_class) { Suma::Member::ResetCode }
  let(:member) { Suma::Fixtures.member.create }
  let(:reset_code) { Suma::Fixtures.reset_code(member:).create }

  it "has a generated six-digit token" do
    expect(reset_code.token).to match(/^\d{6}$/)
  end

  it "expires after 15 minutes" do
    expect(reset_code.expire_at).to be_within(1.minute).of(15.minutes.from_now)
  end

  it "can be expired" do
    expect(reset_code).to be_usable
    expect(reset_code).to_not be_expired
    expect(reset_code).to_not be_used
    reset_code.expire!
    expect(reset_code.expire_at).to be_within(1.minute).of(Time.now)
    expect(reset_code).to_not be_usable
    expect(reset_code).to be_expired
    expect(reset_code).to_not be_used
  end

  describe "using" do
    it "sets expire_at to the time of use and marks the code as used" do
      expect(reset_code).to be_usable
      expect(reset_code).to_not be_expired
      expect(reset_code).to_not be_used
      reset_code.use!
      expect(reset_code.expire_at).to be_within(1.minute).of(Time.now)
      expect(reset_code).to_not be_usable
      expect(reset_code).to be_expired
      expect(reset_code).to be_used
    end

    it "marks any unused code on the member as expired" do
      other_code = described_class.create(member:, transport: "sms")
      expect(other_code).to be_usable
      expect(other_code).to_not be_expired
      expect(other_code).to_not be_used

      reset_code.use!
      expect(other_code.refresh.expire_at).to be_within(1.minute).of(Time.now)
      expect(other_code).to_not be_usable
      expect(other_code).to be_expired
      expect(other_code).to_not be_used
    end
  end

  describe "datasets" do
    it "can select only usable codes" do
      used = Suma::Fixtures.reset_code(member:).create.use!
      expired = Suma::Fixtures.reset_code(member:).create(expire_at: 1.minute.ago)
      usable = Suma::Fixtures.reset_code(member:).create

      expect(described_class.usable).to contain_exactly(usable)
    end
  end

  describe "::dispatch_message", reset_configuration: Suma::Member do
    let(:phone) { "12223334444" }
    let(:email) { "a@b.c" }
    let(:member) { Suma::Fixtures.member(phone:, email:).create }

    it "can send the code via sms" do
      code = member.add_reset_code(token: "12345", transport: "sms")
      code.dispatch_message

      expect(Suma::Message::Delivery.all).to contain_exactly(
        have_attributes(
          template: "verification",
          transport_type: "sms",
          to: phone,
          bodies: contain_exactly(
            have_attributes(content: "Your suma verification code is: 12345"),
          ),
        ),
      )
    end

    it "can send the code via email" do
      member.message_preferences!.update(preferred_language: "es")
      code = member.add_reset_code(token: "12345", transport: "email")
      code.dispatch_message

      expect(Suma::Message::Delivery.all).to contain_exactly(
        have_attributes(
          template: "verification",
          transport_type: "email",
          to: email,
          bodies: include(have_attributes(mediatype: "subject", content: "Su código de verificación suma")),
        ),
      )
    end
  end
end
