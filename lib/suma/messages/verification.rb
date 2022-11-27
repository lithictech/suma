# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::Verification < Suma::Message::Template
  def self.fixtured(recipient)
    code = Suma::Fixtures.reset_code(member: recipient).create
    return self.new(code)
  end

  def initialize(reset_code)
    @reset_code = reset_code
    super()
  end

  def localized? = true

  def liquid_drops
    return super.merge(
      expire_at: @reset_code.expire_at,
      token: @reset_code.token,
    )
  end
end
