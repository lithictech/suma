# frozen_string_literal: true

require "appydays/configurable"
require "liquid"

module Suma::Messages
end

module Suma::Liquid
end

module Suma::Message
  include Appydays::Configurable
  extend Suma::MethodUtilities

  class Error < RuntimeError; end
  class MissingTemplateError < Error; end
  class LanguageNotSetError < Error; end
  class UndeliverableRecipient < Error; end

  DEFAULT_TRANSPORT = :sms
  DATA_DIR = Suma::DATA_DIR + "messages"

  configurable(:messages) do
    after_configured do
      Liquid::Template.error_mode = :strict
      Liquid::Template.file_system = Liquid::LocalFileSystem.new(DATA_DIR, "%s.liquid")
    end
  end

  # Create a Suma::Message::Delivery ready to deliver (rendered, all bodies set up)
  # using the given transport_type to the given user.
  def self.dispatch(template, to, transport_type, extra_fields: {})
    transport = Suma::Message::Transport.registry_create!(transport_type)
    recipient = transport.recipient(to)

    contents = self.render(template, transport_type, recipient)

    Suma::Message::Delivery.db.transaction do
      delivery = Suma::Message::Delivery.create(
        template: template.full_template_name,
        template_language: template.language || "",
        transport_type: transport.type,
        transport_service: transport.carrier.name,
        to: recipient.to,
        recipient: recipient.member,
        extra_fields: template.extra_fields.merge(extra_fields),
        sensitive: template.sensitive?,
      )
      transport.add_bodies(delivery, contents)
      delivery.publish_deferred("dispatched", delivery.id)
      return delivery
    end
  end

  # Render the transport-specific version of the given template
  # and return a the rendering (content and exposed variables).
  #
  # Templates can expose data to the caller by using the 'expose' tag,
  # like {% expose subject %}Hello from Suma!{% endexpose %}.
  # This is available as [:subject] on the returned rendering.
  def self.render(template, transport_type, recipient)
    template_file = template.template_path(transport_type)
    raise MissingTemplateError, "#{template_file} does not exist" unless template_file.exist?

    drops = template.liquid_drops.stringify_keys.merge(
      "recipient" => Suma::Message::MemberDrop.new(recipient),
      "environment" => Suma::Message::EnvironmentDrop.new,
      "app_url" => Suma.app_url,
    )

    content_tmpl = Liquid::Template.parse(template_file.read)
    content_tmpl.registers[:exposed] = {}
    content = content_tmpl.render!(drops, strict_variables: true)

    transport = Suma::Message::Transport.registry_create!(transport_type)
    if transport.supports_layout?
      layout_file = template.layout_path(transport_type)
      if layout_file
        raise MissingTemplateError, "#{layout_file} does not exist" unless layout_file.exist?
        layout_tmpl = Liquid::Template.parse(layout_file.read)
        drops["content"] = content.dup
        content = layout_tmpl.render!(drops, strict_variables: true, registers: content_tmpl.registers)
      end
    end

    return Rendering.new(content, content_tmpl.registers[:exposed])
  end

  def self.send_unsent
    unsent = Suma::Message::Delivery.unsent.to_a
    unsent.each(&:send!)
    return unsent
  end

  # Presents a homogeneous interface for a given 'to' value (email vs. member, for example).
  # +to+ and +formatted_to+ will always be strings, and +member+ will be a +Suma::Member+ or +nil+.
  class Recipient
    attr_reader :to, :member, :formatted_to

    def initialize(to, member, formatted_to)
      @to = to
      @member = member
      @formatted_to = formatted_to
    end
  end

  # String-like type representing the output of a rendering operation.
  # Use [key] to access exposed variables, as per +LiquidExpose+.
  class Rendering
    attr_reader :contents, :exposed

    def initialize(contents, exposed={})
      @contents = contents
      @exposed = exposed
    end

    def [](key)
      return self.exposed[key]
    end

    def to_s
      return self.contents
    end

    def respond_to_missing?(name, *args)
      return true if super
      return self.contents.respond_to?(name)
    end

    def method_missing(name, *, &)
      return self.contents.respond_to?(name) ? self.contents.send(name, *, &) : super
    end
  end
end

require_relative "liquid/expose"
require_relative "liquid/filters"
require_relative "liquid/liquification"
require_relative "liquid/partial"

require_relative "message/carrier"
require_relative "message/transport"
require_relative "message/liquid_drops"
require_relative "message/template"
