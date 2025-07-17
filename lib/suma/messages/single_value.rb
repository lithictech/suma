# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::SingleValue < Suma::Message::Template
  def self.fixtured(recipient)
    msg = self.new(
      "anon_proxy",
      "lime_deep_link_access_code",
      "https://mysuma.org/some-lime-link-#{recipient.id}",
    )
    msg.language = ["es", "en"].sample
    return msg
  end

  def initialize(folder, template, value)
    @folder = folder
    @template = template
    @value = value
    super()
  end

  def localized? = true

  def template_folder = @folder
  def template_name = @template

  def liquid_drops
    return super.merge(
      value: @value,
    )
  end
end
