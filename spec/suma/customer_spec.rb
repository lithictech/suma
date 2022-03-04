# frozen_string_literal: true

RSpec.describe "Suma::Customer", :db do
  let(:described_class) { Suma::Customer }

  it "can be inspected" do
    expect { Suma::Customer.new.inspect }.to_not raise_error
  end

  describe "greeting" do
    it "uses the name if present" do
      expect(described_class.new(name: "Huck Finn").greeting).to eq("Huck Finn")
    end

    it "uses the default if none can be parsed" do
      expect(described_class.new.greeting).to eq("there")
    end
  end

  context "ensure_role" do
    let(:customer) { Suma::Fixtures.customer.create }
    let(:role) { Suma::Role.create(name: "customer-test") }
    it "can set a role by a role object" do
      customer.ensure_role(role)

      expect(customer.roles).to contain_exactly(role)
    end

    it "can set a role by the role name" do
      customer.ensure_role(role.name)
      expect(customer.roles).to contain_exactly(role)
    end

    it "noops if the customer already has the role" do
      customer.ensure_role(role.name)
      customer.ensure_role(role.name)
      customer.ensure_role(role)
      customer.ensure_role(role)
      expect(customer.roles).to contain_exactly(role)
    end
  end

  describe "authenticate" do
    let(:password) { "testtest1" }

    it "returns true if the password matches" do
      u = Suma::Customer.new
      u.password = password
      expect(u.authenticate(password)).to be_truthy
    end

    it "returns false if the password does not match" do
      u = Suma::Customer.new
      u.password = "testtest1"
      expect(u.authenticate("testtest2")).to be_falsey
    end

    it "returns false if the new password is blank" do
      u = Suma::Customer.new
      expect(u.authenticate(nil)).to be_falsey
      expect(u.authenticate("")).to be_falsey

      space = "          "
      u.password = space
      expect(u.authenticate(space)).to be_truthy
    end

    it "cannot auth after being removed" do
      u = Suma::Fixtures.customer.create
      u.soft_delete
      u.password = password
      expect(u.authenticate(password)).to be_falsey
    end
  end

  describe "setting password" do
    let(:customer) { Suma::Fixtures.customer.instance }

    it "sets the digest to a bcrypt hash" do
      customer.password = "abcdefg123"
      expect(customer.password_digest.to_s).to have_length(described_class::PLACEHOLDER_PASSWORD_DIGEST.to_s.length)
    end

    it "uses the placeholder for a nil password" do
      customer.password = nil
      expect(customer.password_digest).to be === described_class::PLACEHOLDER_PASSWORD_DIGEST
    end

    it "fails if the password is not complex enough" do
      expect { customer.password = "" }.to raise_error(described_class::InvalidPassword)
    end
  end

  describe "verification" do
    let(:c) { Suma::Fixtures.customer.unverified.instance }
    after(:each) do
      described_class.reset_configuration
    end

    it "does not change timestamp if already set" do
      expect(c).to_not be_phone_verified
      expect(c).to_not be_email_verified

      c.verify_phone
      c.verify_email
      expect(c).to be_phone_verified
      expect(c).to be_email_verified

      expect { c.verify_phone }.to(not_change { c.phone_verified_at })
      expect { c.verify_email }.to(not_change { c.email_verified_at })
    end

    it "verifies email if configured to skip" do
      described_class.handle_verification_skipping(c)
      expect(c).to_not be_email_verified
      expect(c).to_not be_phone_verified

      described_class.skip_email_verification = true
      described_class.handle_verification_skipping(c)
      expect(c).to be_email_verified
      expect(c).to_not be_phone_verified
    end

    it "verifies phone if configured to skip" do
      described_class.handle_verification_skipping(c)
      expect(c).to_not be_phone_verified
      expect(c).to_not be_email_verified

      described_class.skip_phone_verification = true
      described_class.handle_verification_skipping(c)
      expect(c).to be_phone_verified
      expect(c).to_not be_email_verified
    end

    it "verifies email and phone if allowlisted" do
      described_class.skip_verification_allowlist = ["*autoverify@lithic.tech"]
      c.email = "rob@lithic.tech"
      described_class.handle_verification_skipping(c)
      expect(c).to_not be_email_verified
      expect(c).to_not be_phone_verified

      c.email = "rob+autoverify@lithic.tech"
      described_class.handle_verification_skipping(c)
      expect(c).to be_email_verified
      expect(c).to be_phone_verified
    end
  end

  describe "onboarded?" do
    let(:onboarded) do
      Suma::Fixtures.customer.create(
        password: "password",
        legal_entity: Suma::Fixtures.legal_entity.with_address.create,
      )
    end
    it "is true if name, email, phone, and password are set" do
      c = onboarded

      expect(c.refresh).to be_onboarded
      expect(c.refresh.set(name: "")).to_not be_onboarded
      expect(c.refresh.set(phone: "")).to_not be_onboarded
      expect(c.refresh.set(email: "")).to_not be_onboarded
      expect(c.refresh.set(password_digest: described_class::PLACEHOLDER_PASSWORD_DIGEST)).to_not be_onboarded
    end
  end

  describe "legal entity" do
    let(:c) { Suma::Fixtures.customer.with_legal_entity.instance }

    it "gets its name copied on customer update if it is blank" do
      c.legal_entity.update(name: "")
      c.update(name: "Jim Davis")
      expect(c.legal_entity.refresh).to have_attributes(name: "Jim Davis")
    end

    it "gets its name copied on customer update if it matches the previous value" do
      c.update(name: "Jim Davis")
      c.legal_entity.update(name: "Jim Davis")
      c.update(name: "James Davis")
      expect(c.legal_entity.refresh).to have_attributes(name: "James Davis")
    end

    it "does not change if distinct" do
      c.update(name: "Jim Davis")
      c.legal_entity.update(name: "Garfield")
      c.update(name: "James Davis")
      expect(c.legal_entity.refresh).to have_attributes(name: "Garfield")
    end
  end

  describe "soft deleting" do
    it "sets email and password" do
      c = Suma::Fixtures.customer(email: "a@b.c", password: "password").create
      expect do
        c.soft_delete
      end.to(change { c.password_digest })
      expect(c.email).to match(/^[0-9]+\.[0-9]+\+a@b\.c$/)
    end

    it "sets phone to an invalid, unused phone number" do
      c = Suma::Fixtures.customer(phone: "15551234567").create
      c.soft_delete
      expect(c.phone).to_not eq("15551234567")
      expect(c.phone).to have_length(15)
      expect(c.note).to include("15551234567")
    end

    it "can retrieve the display email" do
      c = Suma::Fixtures.customer(email: "x@y.com").create
      expect(c.display_email).to eq("x@y.com")
      c.soft_delete
      expect(c.display_email).to eq("x@y.com")
    end
  end
end
