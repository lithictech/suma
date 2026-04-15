# frozen_string_literal: true

module Suma::Payment
  class Error < StandardError; end

  # Raised when checking validity fails.
  class Invalid < Error
    attr_reader :reasons

    def initialize(msg, reasons: [])
      super(msg)
      @reasons = reasons
    end
  end

  # Raised when a payment method is unsupported.
  class UnsupportedMethod < Error; end

  # Structured error to communicate failures from a lower level (strategy)
  # to higher level (localized UI strings).
  class CodedError < Error
    # Human-readable message for the error ("Your card was declined.")
    attr_reader :message
    # Type of error ("card_error").
    attr_reader :type
    # Top-level code for the error ("card_declined").
    attr_reader :code
    # Sub-code for the error ("do_not_honor").
    # Not always set but prefer this when it is.
    attr_reader :sub_code
    # <type>.<code>.<subcode> or <type>.<code>
    attr_reader :fqn_code
    # Error code that is a member of en/strings.json[error.*].
    attr_reader :localized_error_code

    def initialize(message:, type:, code:, localized_error_code:, sub_code: "")
      @message = message
      @type = type
      @code = code
      @sub_code = sub_code
      @fqn_code = [type, code, sub_code].select(&:present?).join(".")
      @localized_error_code = localized_error_code
      super(message)
    end
  end
end
