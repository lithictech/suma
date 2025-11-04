# frozen_string_literal: true

require "appydays/loggable"

# Manage the revocation of service access among the various services Suma has integrations with,
# which require external revocation (generally services that use the anonymous proxy system).
# Rather than have the VendorConfigurations or some other system automatically register
# some type of 'uninstall' hook, we centralize the logic here.
# It's very possible that in the future this can all be made more generic.
class Suma::Program::ServiceRevoker
  include Appydays::Loggable

  def self.check_transaction!
    Suma::Postgres.check_transaction(
      Suma::Member.db,
      "Service revocation has side effects, and should be idempotent, so can/should not use a transaction.",
    )
  end

  # Run service revocation for each member that cannot use services.
  # We apply a number of heuristics to avoid querying members who are not eligible
  # for revocation, and ensure we only attempt to revoke when there is
  # some actionable reason.
  # In the worst case, revocation is idempotent, so calling it multiple times
  # won't have a negative impact.
  def self.run
    check_transaction!
    balances = Suma::Payment::Ledger::Balance
    # We only care about cash balances,
    balances = balances.where(ledger_name: "Cash")
    # with a negative balance, or one lower than the minimal balance (which can be positive),
    ok_balance = [Suma::Payment.minimum_cash_balance_for_services_cents, 0].max
    balances = balances.where { balance_cents < ok_balance }
    # which have changed recently (assume we've acted on things older than this)
    balances = balances.where { latest_transaction_at > (Time.now - Suma::Program.service_revoker_lookback) }
    balances = balances.all
    balances.each do |balance|
      self.run_for(balance.ledger)
    end
  end

  def self.run_for(ledger)
    return unless ledger.name == "Cash"
    member = ledger.account.member
    return unless member
    if Suma::Program.service_revoker_dry_run
      self._revoke_if_cannot_use(member)
    else
      idem_key = "service-revoker-#{member.id}-#{ledger.balance_view.latest_transaction_at}"
      Suma::Idempotency.once_ever.under_key(idem_key) do
        self._revoke_if_cannot_use(member)
      end
    end
  end

  def self._revoke_if_cannot_use(member)
    return if Suma::Payment.can_use_services?(member.payment_account)
    self.revoke_member_service_access(member)
  end

  def self.revoke_member_service_access(member)
    self.close_lime_accounts(member)
    self.revoke_all_lyft_passes(member)
  end

  # Remove member access to all Lime AnonProxy accounts in suma (generally just one).
  # This sets the account as pending closure, then requests a new magic link.
  # When the link is received (see +Suma::AnonProxy::MessageHandler::Lime+),
  # we exchange the token, which logs the user out of all other devices,
  # and un-mark the account as pending closure.
  #
  # It also trashes the existing member contact tied to the vendor account,
  # so the user can log in with a new valid account (since the old account
  # is logged out of the device for 90 days as per Lime).
  #
  # This method is idempotent:
  # - vendor accounts pending closure re-request a magic link (processing this is also idempotent);
  # - vendor accounts already closed no longer have a member contact so are skipped.
  #
  def self.close_lime_accounts(member)
    check_transaction!
    lime_configs = Suma::AnonProxy::VendorConfiguration.where(auth_to_vendor_key: "lime").all
    vendor_accounts = member.anon_proxy_vendor_accounts_dataset.
      where(configuration: lime_configs).
      exclude(contact_id: nil).
      all
    return if vendor_accounts.empty?
    if Suma::Program.service_revoker_dry_run
      vendor_accounts.each do |va|
        self.logger.warn(
          "service_revoker_dry_run",
          action: "close_lime",
          vendor_account_id: va.id,
          member_name: va.member.name,
        )
      end
      return
    end
    # Update accounts by ID to make sure we're looking at a consistent set of rows.
    Suma::AnonProxy::VendorAccount.where(id: vendor_accounts.map(&:id)).update(pending_closure: true)
    # Request a new magic link for each account. See method doc for explanation.
    vendor_accounts.each do |va|
      Suma::AnonProxy::AuthToVendor::Lime.new(va).auth
    end
  end

  # Revoke access to all Lyft Pass programs.
  # Generally this is only used for global changes,
  # like when a user loses access to services due to a negative ledger.
  def self.revoke_all_lyft_passes(member)
    registrations = Suma::AnonProxy::VendorAccountRegistration.where(
      account: member.anon_proxy_vendor_accounts_dataset.where(
        configuration: Suma::AnonProxy::VendorConfiguration.where(auth_to_vendor_key: "lyft_pass"),
      ),
    ).all
    self.revoke_lyft_passes(registrations)
  end

  # Revoke the member's access to the Lyft Pass programs represented by
  # the registrations. Registrations are destroyed when revoked,
  # so the member can be granted access to the program again when the suma app allows it.
  #
  # This method is idempotent:
  # - After revoking registration in a program, the registration is destroyed.
  #   At this point, we won't try to re-revoke it.
  #
  # @param [Array<Suma::AnonProxy::VendorAccountRegistration>] registrations
  def self.revoke_lyft_passes(registrations)
    check_transaction!
    return if registrations.empty?
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    registrations.each do |r|
      member = r.account.member
      # If we're running this after member deletion, use their previous phone as what was previous valid.
      phone = member.soft_deleted? ? member.previous_phones.first : member.phone
      if Suma::Program.service_revoker_dry_run
        self.logger.warn(
          "service_revoker_dry_run",
          action: "revoke_lyft",
          phone:,
          registration_id: r.id,
          lyft_pass_program_id: r.external_program_id,
          vendor_account_id: r.account_id,
          member_name: member.name,
        )
      else
        lp.revoke_member(r.account.member, program_id: r.external_program_id, phone:) if phone
        r.destroy
      end
    end
  end
end
