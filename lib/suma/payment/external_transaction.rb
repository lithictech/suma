# frozen_string_literal: true

require "suma/external_links"
require "suma/payment"

# Funding and Payout Transactions have almost the same behavior,
# but are totally separate things conceptually (and always have different strategies)
# so have different database models.
# This class exists to colocate the shared behavior.
module Suma::Payment::ExternalTransaction
  def self.included(mod)
    mod.include(Suma::ExternalLinks)
    mod.extend(ClassMethods)
    mod.include(InstanceMethods)
  end

  module ClassMethods
    # Force a fake strategy within a block. Mostly used for API tests,
    # since you can otherwise pass strategy explicitly to start_new.
    def force_fake(strat)
      raise LocalJumpError unless block_given?
      raise ArgumentError, "strat cannot be nil" if strat.nil?
      @fake_strategy = strat
      begin
        return yield
      ensure
        @fake_strategy = nil
      end
    end
  end

  module InstanceMethods
    def _external_links_self
      return [self.strategy]
    end

    # @return [Suma::Payment::FundingTransaction::Strategy,Suma::Payment::PayoutTransaction::Strategy]
    def strategy
      strat = self.strategy_array.compact.first
      return strat if strat
      return nil if self.new?
      raise "#{self.class.name}[#{self.id}] has no strategy set, should not have been possible due to constraints"
    end

    # @param [Suma::Payment::FundingTransaction::Strategy,Suma::Payment::PayoutTransaction::Strategy] strat
    def strategy=(strat)
      # We cannot just do strat.payment = self, it triggers a save and we're not valid yet/don't want that
      self.class.association_reflections.each_value do |details|
        type_match = details[:class_name] == strat.class.name
        next unless type_match
        self.associations[details[:name]] = strat
        self.send("#{details[:name]}_id=", strat.id)
        strat.associations[:payment] = self
        # rubocop:disable Lint/NonLocalExitFromIterator
        return
        # rubocop:enable Lint/NonLocalExitFromIterator
      end
      raise "Strategy type #{strat.class.name} does not match any association type on #{self.class.name}"
    end

    protected def strategy_array
      raise NotImplementedError
    end

    def _put_into_review_helper(message, opts={})
      reason = nil
      if opts[:reason]
        reason = opts[:reason]
      elsif (ex = opts[:exception])
        reason = ex.class.name
        message = "#{message}: #{ex}"
        reason = ex.wrapped.class.name if ex.respond_to?(:wrapped)
      end
      self.audit(message, reason:)
      Suma::Support::Ticket.create(
        sender_name: "Suma Payments",
        subject: "#{self.class.name.split('::').last} Needs Review",
        body: "#{self.class.name}[#{self.id}] was put into review (reason=#{reason}): #{message}",
      )
    end

    protected def _originate_book_transaction(originating_ledger:, receiving_ledger:)
      return unless self.originated_book_transaction.nil?
      associated_vendor_service_category = Suma::Vendor::ServiceCategory.cash
      originated_book_transaction = Suma::Payment::BookTransaction.create(
        apply_at: Suma.request_now,
        amount: self.amount,
        originating_ledger:,
        receiving_ledger:,
        associated_vendor_service_category:,
        memo: self.memo,
      )
      # If the transaction fails, this gets reversed (adds a new inverted 'reversal book transaction')
      self.originated_book_transaction = originated_book_transaction
    end

    protected def _reverse_originated_book_transaction
      return unless self.reversal_book_transaction.nil? && (orig_bx = self.originated_book_transaction)
      self.db.transaction do
        reversal_book_transaction = Suma::Payment::BookTransaction.create(
          apply_at: Suma.request_now,
          amount: orig_bx.amount,
          originating_ledger: orig_bx.receiving_ledger,
          receiving_ledger: orig_bx.originating_ledger,
          associated_vendor_service_category: orig_bx.associated_vendor_service_category,
          memo: self.memo,
        )
        self.update(reversal_book_transaction:)
      end
    end

    #
    # :section: Sequel Hooks
    #

    def after_save
      super
      # Save the strategy changes whenever we save the payment, otherwise it's very easy to forget.
      self.strategy&.save_changes
    end

    def validate(*)
      super
      self.strategy_present
    end

    private def strategy_present
      errors.add(:strategy, "is not available using strategy associations") unless self.strategy_array.any?
    end
  end
end
