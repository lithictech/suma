# frozen_string_literal: true

module Suma::Payment::FinancialModeling; end

class Suma::Payment::FinancialModeling::Model202309
  # Return decimals with full precision for accuracy
  Money.default_infinite_precision = true
  # 0.5% fee charged to all money a user moves onto the platform
  USER_TRANSACTION_FEE = 0.005
  # 1% fee charged to product subsidy (for example the $19 subsidy on $24 in vouchers)
  SUBSIDY_TRANSACTION_FEE = 0.01
  # Hard-coded Stripe fee for now
  MERCHANT_FEE_SURCHARGE = Money.new(30)
  MERCHANT_FEE_PERCENT = 0.029
  BEGINNING_LIABILITY_AMOUNT = Money.new(0)
  STRIPE_DEPOSITS_AMOUNT = Money.new(4_500_00)

  TRANSPORTATION = "Transportation"
  FOOD = "Food"
  UTILITIES = "Utilities"
  SECTOR_NUMBERS = {
    TRANSPORTATION => 100,
    FOOD => 200,
    UTILITIES => 300,
  }.freeze
  # EMPTY = ""
  EMPTY_GL_NUMBER = "----"
  EMPTY_SECTOR_NUMBER = "---"
  # EXPENSE = "Expense"
  # REVENUE = "Revenue"
  # PARTICIPATION_FEE_VENDOR = "Platform Participation Fees - Vendor"
  # PARTICIPATION_FEE_USER = "Platform Participation Fees - User"
  # PARTICIPATION_FEE_SUBSIDY = "Platform Participation Fees - Subsidy"
  TRANSACTION_FEE_VENDOR = "Platform Transaction Fees - Vendor"
  TRANSACTION_FEE_USER = "Platform Transaction Fees - User"
  TRANSACTION_FEE_SUBSIDY = "Platform Transaction Fees - Subsidy"
  USER_PAYMENT = "User payments for Platform Products"
  SUBSIDY = "Subsidy for Platform Products"
  # DISCOUNT = "Vendor Discounts for Platform Products"
  PRODUCTS = "Platform Products"
  MERCHANT_FEES = "Merchant Fees"
  STRIPE_DEPOSITS = "Deposits"
  BEGINNING_LIABILITY_BALANCE = "Beginning Liability Balance"
  ENDING_LIABILITY_BALANCE = "Ending Liability Balance"

  GL_NUMBERS = {
    # PARTICIPATION_FEE_VENDOR => 4500,
    # PARTICIPATION_FEE_USER => 4505,
    # PARTICIPATION_FEE_SUBSIDY => 4510,
    TRANSACTION_FEE_VENDOR => 4550,
    TRANSACTION_FEE_USER => 4555,
    TRANSACTION_FEE_SUBSIDY => 4560,

    USER_PAYMENT => 4625,
    SUBSIDY => 4630,
    PRODUCTS => 7101,
    # MERCHANT_FEES => 0000,
  }.freeze

  DEBIT = "debit"
  CREDIT = "credit"

  class LineItem
    attr_accessor :category, :description, :amount, :amount_formatted

    def initialize(category, amount, description)
      self.category = category
      self.amount = amount
      self.description = description
      self.amount_formatted = description == CREDIT ? "(#{amount})" : amount
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
    result << LineItem.new(self.create_category(TRANSACTION_FEE_USER, ""), user_fee, CREDIT)

    # This is strange as we're double-crediting here, but that's because one of these
    # credits are used to pay the vendor, and the other is used to pay Suma.
    result << LineItem.new(self.create_category(SUBSIDY, "", notes: "(User transaction fees)"), user_fee, CREDIT)
    result << LineItem.new(self.create_category(USER_PAYMENT, ""), fx.amount - user_fee, CREDIT)

    # We are not going to bother looking for the Stripe Charge yet. We need BalanceTransaction to get
    # the actual Fee amount, and that's not in WebhookDB yet, so when we add it, we can fetch everything.
    # TODO: Read the merchant fee from Stripe.
    # TODO: Do we need to include this fee? If so, we need to update this with the correct GL, sector codes.
    merchant_fee = MERCHANT_FEE_SURCHARGE + (MERCHANT_FEE_PERCENT * fx.amount)
    # result << LineItem.new(self.create_category(MERCHANT_FEES, ""), merchant_fee, DEBIT)
    # TODO: Do we need to include this fee? If so, we need to update this with the correct GL, sector codes.
    # result << LineItem.new(self.create_category(SUBSIDY, "", notes: "(Merchant fees)"), merchant_fee, CREDIT)
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
      result << LineItem.new(self.create_category(TRANSACTION_FEE_USER, "", notes: "(Refund)"), user_fee, DEBIT)
      result << LineItem.new(self.create_category(SUBSIDY, "", notes: "(Refund User transaction fees)"),
                             user_fee, DEBIT,)
      result << LineItem.new(self.create_category(USER_PAYMENT, "", notes: "(Refund)"), px.amount - user_fee,
                             DEBIT,)
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
    result << LineItem.new(self.create_category(PRODUCTS, sector), ch.undiscounted_subtotal, DEBIT)
    cash_contribution = ch.book_transactions.
      select { |bx| bx.originating_ledger === bx.originating_ledger.account.cash_ledger }.
      sum(Money.new(0), &:amount)
    subsidy_amount = ch.undiscounted_subtotal - cash_contribution
    # Get subsidy money for whatever was not covered by cash
    if subsidy_amount.positive?
      result << LineItem.new(self.create_category(SUBSIDY, sector, notes: "(Products)"), subsidy_amount, CREDIT)
      # And send some money Suma's way
      result << LineItem.new(self.create_category(TRANSACTION_FEE_SUBSIDY, sector),
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
      csv << ["", "2025 User Wallet Liability"]
      csv << [BEGINNING_LIABILITY_BALANCE, BEGINNING_LIABILITY_AMOUNT]
      csv << [STRIPE_DEPOSITS, STRIPE_DEPOSITS_AMOUNT]
      ending_liability_amount = [BEGINNING_LIABILITY_AMOUNT, STRIPE_DEPOSITS_AMOUNT]
      line_items.each do |it|
        csv << [
          it.category,
          it.amount_formatted,
        ]
        ending_liability_amount << it.amount
      end
      csv << [ENDING_LIABILITY_BALANCE, ending_liability_amount.sum(Money.new(0))]
    end
    return got
  end

  # Returns the category label like "[GL_NUMBER]-[SECTOR_NUMBER] [GL_CODE] [NOTES]" plus any additional parts
  def create_category(gl_code, sector, notes: "")
    gl_numbers = "#{GL_NUMBERS.fetch(gl_code, EMPTY_GL_NUMBER)}-#{SECTOR_NUMBERS.fetch(sector, EMPTY_SECTOR_NUMBER)}"
    return [gl_numbers, gl_code, notes].collect(&:strip).join(" ")
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
