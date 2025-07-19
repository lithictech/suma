# frozen_string_literal: true

require "suma/message"

# Template is the base class for all message templates.
# Every message (email, and/or SMS, etc) has a Template
# that defines how to look up its text template and the dynamic data
# for rendering into the template.
# Subclasses should override methods to control the rendering behavior;
# see the method docs to see what is expected to be overridden.
class Suma::Message::Template
  # Override to return a new version of the template,
  # with its data fixtured. It is used for message previewing.
  # The argument is the message recipient,
  # because they may need to be used to build resources off of.
  #
  # Only needs to be overridden if the template constructor takes arguments.
  # Assume that fixtures are loaded when this method is called;
  # do not require them as part of your code.
  def self.fixtured(_recipient)
    return self.new
  end

  attr_accessor :language

  def dispatch(to, transport: Suma::Message::DEFAULT_TRANSPORT)
    return Suma::Message.dispatch(self, to, transport)
  end

  # Return true if this message template supports localization.
  # Localized templates are stored as +Suma::I18n::StaticString+ rows in the 'messages' namespace.
  def localized? = false

  # Return true if this message template contains sensitive information.
  # Sensitive templates are not rendered in admin,
  # except for users with the necessary role.
  def sensitive? = false

  # The folder containing this template. Templates in the root template directory should use nil.
  def template_folder
    return nil
  end

  # The name of the template. By default, it is tied to the name of the class,
  # so Messages::NewMember looks for 'new_member' templates.
  # However, a subclass can override this to not tie the template to the class name.
  def template_name
    return self.class.name.demodulize.underscore
  end

  def full_template_name
    fld = self.template_folder.present? ? "#{self.template_folder}/" : ""
    return "#{fld}#{self.template_name}"
  end

  def template_string(transport)
    unless self.localized?
      path = Suma::Message::DATA_DIR + "templates/#{self.full_template_name}.#{transport}.liquid"
      raise Suma::Message::MissingTemplateError, "#{path} does not exist" unless path.exist?
      return path.read
    end
    raise Suma::Message::LanguageNotSetError if self.language.nil?
    criteria = self.static_string_criteria(transport)
    template = Suma::I18n::StaticString.find(**criteria)
    raise Suma::Message::MissingTemplateError, "No static string row: #{criteria}" if
      template.nil?
    content = template.text&.send(self.language)
    raise Suma::Message::MissingTemplateError, "Message blank: #{criteria.merge(lang: self.language)}" if
      content.nil?
    return content
  end

  def static_string_criteria(transport)
    criteria = {
      namespace: Suma::Message::STATIC_STRING_NAMESPACE,
      key: "#{self.full_template_name}.#{transport}",
    }
    return criteria
  end

  # The layout for the template. See the 'layouts' folder in the message data directory.
  def layout
    return "standard"
  end

  def layout_path(transport)
    return nil if self.layout.nil?
    return Suma::Message::DATA_DIR + "layouts/#{self.layout}.#{transport}.liquid"
  end

  # The hash that is used for the rendering of the template.
  # These must be simple types (strings, ints, bools, etc), or Liquid::Drop subclasses.
  # By default, templates are rendered with some default variables,
  # such as 'recipient', 'environment', and 'app_url'.
  def liquid_drops
    return {}
  end

  # Liquify wraps any object in a Liquification.
  def liquify(o)
    return Suma::Liquid::Liquification.new(o)
  end

  # Return a hash of special fields for that this delivery should use.
  # Necessary for deliveries that need to carry along some metadata. For example:
  #   {'reply_to' => 'member@gmail.com'}
  # for members who send support requests.
  # These fields are subject to flux and change and may only be applicable to some transports.
  def extra_fields
    return {}
  end
end
