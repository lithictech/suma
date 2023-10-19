# frozen_string_literal: true

module Suma::Payment::FinancialModeling; end

class Suma::Payment::FinancialModeling::Model202309
  # 0.5% fee charged to all money a user moves onto the platform
  USER_TRANSACTION_FEE = 0.005
  # 1% fee charged to product subsidy (for example the $19 subsidy on $24 in vouchers)
  SUBSIDY_TRANSACTION_FEE = 0.01
  # Hard-coded Stripe fee for now
  MERCHANT_FEE_SURCHARGE = Money.new(30)
  MERCHANT_FEE_PERCENT = 0.029

  TRANSPORTATION = "Transportation"
  FOOD = "Food"
  UTILITIES = "Utilities"
  SECTOR_NUMBERS = {
    TRANSPORTATION => 100,
    FOOD => 200,
    UTILITIES => 300,
  }.freeze
  EMPTY = ""
  EXPENSE = "Expense"
  REVENUE = "Revenue"
  PARTICIPATION_FEE_VENDOR = "Platform Participation Fees - Vendor"
  PARTICIPATION_FEE_USER = "Platform Participation Fees - User"
  PARTICIPATION_FEE_SUBSIDY = "Platform Participation Fees - Subsidy"
  TRANSACTION_FEE_VENDOR = "Platform Transaction Fees - Vendor"
  TRANSACTION_FEE_USER = "Platform Transaction Fees - User"
  TRANSACTION_FEE_SUBSIDY = "Platform Transaction Fees - Subsidy"
  USER_PAYMENT = "User payments for Platform Products"
  SUBSIDY = "Subsidy for Platform Products"
  DISCOUNT = "Vendor Discounts for Platform Products"
  PRODUCTS = "Platform Products"
  MERCHANT_FEES = "Merchant Fees"

  GL_NUMBERS = {
    PARTICIPATION_FEE_VENDOR => 4500,
    PARTICIPATION_FEE_USER => 4505,
    PARTICIPATION_FEE_SUBSIDY => 4510,
    TRANSACTION_FEE_VENDOR => 4550,
    TRANSACTION_FEE_USER => 4555,
    TRANSACTION_FEE_SUBSIDY => 4560,
  }.freeze

  DEBIT = "debit"
  CREDIT = "credit"

  class LineItem
    attr_accessor :date, :gl_type, :gl_code, :sector, :amount, :description, :note, :gl_number, :sector_number

    def initialize(date, gl_type, gl_code, sector, amount, description, note=nil)
      self.date = date
      self.gl_type = gl_type
      self.gl_code = gl_code
      self.sector = sector
      self.description = description
      self.amount = description == CREDIT ? "(#{amount})" : amount
      self.note = note || EMPTY
      self.gl_number = GL_NUMBERS.fetch(self.gl_code, EMPTY)
      self.sector_number = SECTOR_NUMBERS.fetch(self.sector, EMPTY)
    end
  end

  # If this is a funding transaction, generate these line items:
  # - The user transaction fee
  # - The subsidy reimbursing the user fee
  # - User 'payment for products' (which happens in the future but is recorded now)
  # - The merchant fee charged by Stripe
  # - The subsidy reimbursing the merchant fee
  #
  # @param fx [Suma::Payment::FundingTransaction]
  def funding_xaction_line_items(fx)
    result = []
    user_fee = fx.amount * USER_TRANSACTION_FEE
    result << LineItem.new(fx.created_at, REVENUE, TRANSACTION_FEE_USER, EMPTY, user_fee, CREDIT)
    # This is strange as we're double-crediting here, but that's because one of these
    # credits are used to pay the vendor, and the other is used to pay Suma.
    result << LineItem.new(fx.created_at, REVENUE, SUBSIDY, EMPTY, user_fee, CREDIT, "User transaction fees")
    result << LineItem.new(fx.created_at, REVENUE, USER_PAYMENT, EMPTY, fx.amount - user_fee, CREDIT)

    # We are not going to bother looking for the Stripe Charge yet. We need BalanceTransaction to get
    # the actual Fee amount, and that's not in WebhookDB yet, so when we add it, we can fetch everything.
    # TODO: Read the merchant fee from Stripe.
    merchant_fee = MERCHANT_FEE_SURCHARGE + (MERCHANT_FEE_PERCENT * fx.amount)
    result << LineItem.new(fx.created_at, EXPENSE, MERCHANT_FEES, EMPTY, merchant_fee, DEBIT)
    result << LineItem.new(fx.created_at, REVENUE, SUBSIDY, EMPTY, merchant_fee, CREDIT, "Merchant fees")
    return result
  end

  # If this is a payout transaction,
  # and it is a refund/reversal, we generate these line items:
  # - A 'reverse' of the money (say $4.975) that the user is using for products
  # - A 'reverse' of the subsidy ($0.025) given to Suma so that we could show the user $5 in the app
  # - A 'reverse' of the user transaction fee ($0.025), since it's reversed
  #   (note, we could keep this fee, like Stripe does)
  # We do not refund the merchant fee or subsidy since Stripe keeps it for refunds.
  #
  # @param px [Suma::Payment::PayoutTransaction]
  def payout_xaction_line_items(px)
    result = []
    if ["refund", "reversal"].include?(px.classification)
      user_fee = px.amount * USER_TRANSACTION_FEE
      result << LineItem.new(px.created_at, EXPENSE, TRANSACTION_FEE_USER, EMPTY, user_fee, DEBIT, "Refund")
      result << LineItem.new(px.created_at, EXPENSE, SUBSIDY, EMPTY, user_fee, DEBIT, "Refund User transaction fees")
      result << LineItem.new(px.created_at, EXPENSE, USER_PAYMENT, EMPTY, px.amount - user_fee, DEBIT, "Refund")
    else
      raise TypeError, "cannot handle #{px.classification}"
    end
    return result
  end

  # For a charge, we can:
  # - Figure out the sector based on the associated product (order vs. trip)
  # - Get the product charge as the undiscounted amount
  #   (that is, what the user had to paid, including subsidy)
  # - Get the subsidy based on the undiscounted amount, minus book transactions
  #   from the cash ledger.
  # - Charge the subsidy fee of 1%
  # @param ch [Suma::Charge]
  def charge_line_items(ch)
    result = []
    sector = if ch.mobility_trip_id
               TRANSPORTATION
    elsif ch.commerce_order_id
      FOOD
    else
      "Unknown"
    end
    # Charge for the goods sold
    result << LineItem.new(ch.created_at, EXPENSE, PRODUCTS, sector, ch.undiscounted_subtotal, DEBIT)
    cash_contribution = ch.book_transactions.
      select { |bx| bx.originating_ledger === bx.originating_ledger.account.cash_ledger }.
      sum(Money.new(0), &:amount)
    subsidy_amount = ch.undiscounted_subtotal - cash_contribution
    # Get subsidy money for whatever was not covered by cash
    if subsidy_amount.positive?
      result << LineItem.new(ch.created_at, REVENUE, SUBSIDY, sector, subsidy_amount, CREDIT, "Products")
      # And send some money Suma's way
      result << LineItem.new(ch.created_at, REVENUE, TRANSACTION_FEE_SUBSIDY, sector,
                             subsidy_amount * SUBSIDY_TRANSACTION_FEE, CREDIT,)
    end
    return result
  end

  def build_model(month=Date.today)
    m = month.to_datetime
    period = m.beginning_of_month..m.end_of_month
    bx_ds = Suma::Payment::BookTransaction.where(apply_at: period)
    fx = Suma::Payment::FundingTransaction.where(originated_book_transaction: bx_ds).all
    px = Suma::Payment::PayoutTransaction.where(created_at: period).all
    charges = Suma::Charge.where(created_at: period).all
    line_items = []
    charges.each { |ch| line_items.concat(self.charge_line_items(ch)) }
    fx.each { |f| line_items.concat(self.funding_xaction_line_items(f)) }
    px.each { |p| line_items.concat(self.payout_xaction_line_items(p)) }

    got = CSV.generate do |csv|
      csv << ["Date", "GL Type", "GL Code", "Sector", "Amount", "Description", "GL #", "Sector #", "Note"]
      line_items.each do |it|
        csv << [
          it.date.in_time_zone("America/Los_Angeles").to_date,
          it.gl_type,
          it.gl_code,
          it.sector,
          it.amount,
          it.description,
          it.gl_number,
          it.sector_number,
          it.note,
        ]
      end
    end
    return got
  end

  FEEDBACK = <<~S
    - We added a 'notes' column that has additional info.
    - We don't have GL #s for many GL names
    - Refunds are represented as normal line items, with a note.
    - In the model, the user subsidy fee is mentioned as 0.05%, but it's 0.5%.
    - The funder subsidy calculation needs to be split up. When a user loads funds,
      the merchant fee and user transaction fees are assessed then;
      but the subsidy reimbursement in the model is a combination of the goods subsidy
      ($19), merchant fees ($0.445), and user transaction fee ($0.025).
      Our model has separate items for each.
    - When a user loads cash, that cash cannot be definitively associated with a product.
      For example, they could load $5 and $10, and use $8 for Food.
      This means that in many cases we cannot assign user transaction fees
      or subsidies for those fees to a Sector (there are cases we can, if the charge happens
      as part of 'checkout', but that will not be consistent).
      Those line items do not have a Sector in the our model.
      They use the same GL Code but have a note indicating the purpose of the subsidy, etc.
  S
end
