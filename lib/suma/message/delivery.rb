# frozen_string_literal: true

require "suma/postgres/model"

require "suma/message"

class Suma::Message::Delivery < Suma::Postgres::Model(:message_deliveries)
  plugin :timestamps

  many_to_one :recipient, class: "Suma::Customer"
  one_to_many :bodies, class: "Suma::Message::Body"

  dataset_module do
    def unsent
      return self.where(aborted_at: nil, sent_at: nil)
    end

    def to_customers(customers)
      emails = customers.is_a?(Sequel::Dataset) ? customers.select(:email) : customers.map(&:email)
      return self.where(Sequel[to: emails] | Sequel[recipient: customers])
    end
  end

  def initialize(*)
    super
    self[:extra_fields] ||= {}
  end

  def body_with_mediatype(mt)
    return self.bodies.find { |b| b.mediatype == mt }
  end

  def body_with_mediatype!(mt)
    (b = self.body_with_mediatype(mt)) or raise "Delivery #{self.id} has no body with mediatype #{mt}"
    return b
  end

  def send!
    return nil if self.sent_at || self.aborted_at
    self.db.transaction do
      self.lock!
      return nil if self.sent_at || self.aborted_at
      unless self.transport.allowlisted?(self)
        self.update(aborted_at: Time.now)
        return self
      end
      transport_message_id = self.transport.send!(self)
      if transport_message_id.blank?
        self.logger.error("empty_transport_message_id", message_delivery_id: self.id)
        transport_message_id = "WARNING-NOT-SET"
      end
      self.update(transport_message_id:, sent_at: Time.now)
      return self
    end
  end

  def transport
    return Suma::Message::Transport.for(self.transport_type)
  end

  def transport!
    return Suma::Message::Transport.for!(self.transport_type)
  end

  def self.lookup_template_class(name)
    constname = name.split("::").map(&:camelize).join("::")
    fqn = "Suma::Messages::#{constname}"
    begin
      return fqn.constantize
    rescue NameError
      raise Suma::Message::MissingTemplateError, "#{fqn} not found"
    end
  end

  def self.preview(template_class_name, transport: :sms, rack_env: Suma::RACK_ENV, commit: false)
    raise "Can only preview in development" unless rack_env == "development"

    pattern = File.join(Pathname(__FILE__).dirname.parent, "messages", "*.rb")
    Gem.find_files(pattern).each do |path|
      require path
    end

    template_class = self.lookup_template_class(template_class_name)

    require "suma/fixtures"
    Suma::Fixtures.load_all

    delivery = nil
    self.db.transaction(rollback: commit ? nil : :always) do
      to = Suma::Fixtures.customer.create
      template = template_class.fixtured(to)
      delivery = template.dispatch(to, transport:)
      delivery.bodies # Fetch this ahead of time so it is there after rollback
    end
    return delivery
  end
end
