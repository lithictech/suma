# frozen_string_literal: true

require "suma/payment"

# Class that reviews external transactions.
class Suma::Payment::Reviewer
  # @param xaction [Suma::Payment::ExternalTransaction]
  def initialize(xaction)
    @xaction = xaction
  end

  # Take action, like canceling a funding transaction automatically,
  # or creating a support ticket.
  def act
    return self.handle_funding if @xaction.is_a?(Suma::Payment::FundingTransaction)
    Suma.assert { @xaction.is_a?(Suma::Payment::PayoutTransaction) }
    return self.handle_payout
  end

  protected def handle_funding
    success = @xaction.process(:cancel)
    return if success
    self.create_ticket
  end

  protected def handle_payout
    self.create_ticket
  end

  protected def create_ticket
    log = @xaction.audit_logs.last
    Suma::Support::Ticket.create(
      sender_name: "Suma Payments",
      subject: "#{@xaction.admin_label} Needs Review",
      body: [
        "#{@xaction.admin_label} was put into review.",
        "Admin link: #{@xaction.admin_link}",
        "Reason: #{log.reason}",
        "Message: #{log.messages.join(', ')}",
      ].join("\n"),
    )
  end
end
