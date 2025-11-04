# frozen_string_literal: true

RSpec.describe Suma::Program::ServiceRevoker, :db, :no_transaction_check do
  let(:member) { Suma::Fixtures.member.create }

  before(:each) do
    Suma::Program.service_revoker_dry_run = false
  end

  it "errors if in a transaction", no_transaction_check: false do
    expect { described_class.run }.to raise_error(Suma::Postgres::InTransaction)
  end

  def create_cash_ledger
    member = Suma::Fixtures.member.create
    return Suma::Payment.ensure_cash_ledger(member)
  end

  it "revokes service access for members that cannot access services" do
    ledger_to_revoke = create_cash_ledger

    # This large charge is recent enough to see, but old enough that it's past the grace period.
    # Service access should be revoked.
    Suma::Fixtures.book_transaction.
      from(ledger_to_revoke).to(create_cash_ledger).
      create(amount: money("$500"), apply_at: 2.days.ago)

    # This transaction is too old to care about.
    Suma::Fixtures.book_transaction.
      from(create_cash_ledger).to(create_cash_ledger).
      create(amount: money("$500"), apply_at: 10.days.ago)

    # This is not a cash ledger
    Suma::Fixtures.book_transaction.
      create(amount: money("$500"), apply_at: 2.days.ago)

    member = ledger_to_revoke.account.member
    expect(described_class).to receive(:close_lime_accounts).with(member)
    expect(described_class).to receive(:revoke_all_lyft_passes).with(member)
    described_class.run
  end

  it "skips idempotency in dry run" do
    Suma::Program.service_revoker_dry_run = true

    ledger = create_cash_ledger
    Suma::Fixtures.book_transaction.from(ledger).create(amount: money("$500"), apply_at: 2.days.ago)
    member = ledger.account.member
    expect(described_class).to receive(:close_lime_accounts).with(member)
    expect(described_class).to receive(:revoke_all_lyft_passes).with(member)
    described_class.run_for(ledger)
    expect(Suma::Idempotency.all).to be_empty
  end

  describe "revoke_all_lyft_passes" do
    before(:each) do
      Suma::Lyft.reset_configuration

      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: {body: {}, cookies: {}}.to_json,
      )

      Suma::Lyft.pass_authorization = "Basic xyz"
      Suma::Lyft.pass_email = "a@b.c"
      Suma::Lyft.pass_org_id = "1234"
    end

    it "revokes lyft pass and destroys registrations for lyft pass program ids" do
      lyft_pass_config = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lyft_pass")
      lyft_pass_vendor_acct = Suma::Fixtures.anon_proxy_vendor_account.create(configuration: lyft_pass_config, member:)
      reg1 = lyft_pass_vendor_acct.add_registration(external_program_id: "111")
      reg2 = lyft_pass_vendor_acct.add_registration(external_program_id: "222")

      req1 = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/revoke").
        with(body: hash_including("ride_program_id" => "111")).to_return(status: 200)
      req2 = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/revoke").
        with(body: hash_including("ride_program_id" => "222")).to_return(status: 200)

      described_class.revoke_all_lyft_passes(member)

      expect(req1).to have_been_made
      expect(req2).to have_been_made
      expect(reg1).to be_destroyed
      expect(reg2).to be_destroyed
    end

    it "logs and skips idempotency with dry run" do
      Suma::Program.service_revoker_dry_run = true

      lyft_pass_config = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lyft_pass")
      lyft_pass_vendor_acct = Suma::Fixtures.anon_proxy_vendor_account.create(configuration: lyft_pass_config, member:)
      reg1 = lyft_pass_vendor_acct.add_registration(external_program_id: "111")

      logs = capture_logs_from(described_class.logger) do
        described_class.revoke_all_lyft_passes(member)
      end
      expect(logs).to have_a_line_matching(/service_revoker_dry_run/)
      expect(reg1).to_not be_destroyed
    end

    describe "when a member is soft deleted" do
      it "revokes passes of the latest previous number" do
        member.update(phone: "15553334444")
        member.soft_delete
        lyft_pass_config = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lyft_pass")
        lyft_pass_vendor_acct = Suma::Fixtures.anon_proxy_vendor_account.
          create(configuration: lyft_pass_config, member:)
        reg = lyft_pass_vendor_acct.add_registration(external_program_id: "111")

        req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/revoke").
          with(body: hash_including(
            "ride_program_id" => "111",
            "user_identifier" => {"phone_number" => "+15553334444"},
          )).to_return(status: 200)

        described_class.revoke_all_lyft_passes(member)

        expect(req).to have_been_made
        expect(reg).to be_destroyed
      end

      it "does not revoke if there is no previous number" do
        member.update(soft_deleted_at: Time.now)
        lyft_pass_config = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lyft_pass")
        lyft_pass_vendor_acct = Suma::Fixtures.anon_proxy_vendor_account.
          create(configuration: lyft_pass_config, member:)
        reg = lyft_pass_vendor_acct.add_registration(external_program_id: "111")

        described_class.revoke_all_lyft_passes(member)

        expect(reg).to be_destroyed
      end
    end
  end

  describe "close_lime_accounts" do
    it "noops if there are no accounts with contacts in any lime programs" do
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime")
      Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc).create
      expect { described_class.close_lime_accounts(member) }.to_not raise_error
    end

    it "starts the account close process" do
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime")
      contact = Suma::Fixtures.anon_proxy_member_contact.email.create(member:)
      lime_va = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc, contact:).create
      other_va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link").
        to_return(json_response({}))
      described_class.close_lime_accounts(member)
      expect(req).to have_been_made
      lime_va.refresh
      expect(lime_va).to have_attributes(pending_closure: true)
      expect(other_va.refresh).to have_attributes(pending_closure: false)
    end

    it "logs and skips idempotency with dry run" do
      Suma::Program.service_revoker_dry_run = true

      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime")
      contact = Suma::Fixtures.anon_proxy_member_contact.email.create(member:)
      lime_va = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration: vc, contact:).create

      logs = capture_logs_from(described_class.logger) do
        described_class.close_lime_accounts(member)
      end
      expect(logs).to have_a_line_matching(/service_revoker_dry_run/)
      expect(lime_va.refresh).to have_attributes(pending_closure: false)
    end
  end
end
