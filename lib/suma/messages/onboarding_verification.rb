# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::OnboardingVerification < Suma::Message::Template
  def initialize(member)
    @member = member
    super()
  end

  def localized? = true
end
