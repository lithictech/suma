# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::SingleValue < Suma::Message::Template
  def self.fixtured(recipient)
    tmpl = self.new(
      "anon_proxy",
      "lime_deep_link_access_code",
      "https://mysuma.org/some-lime-link-#{recipient.id}",
    )
    Suma::Fixtures.static_string.
      message(tmpl, "sms").
      text("test single value (en)", es: "test single value (es)").
      create
    return tmpl
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
