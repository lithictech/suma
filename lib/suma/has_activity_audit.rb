# frozen_string_literal: true

# Mixin for the subject of an activity.
module Suma::HasActivityAudit
  def self.included(m)
    m.one_to_many :audit_activities,
                  class: "Suma::Member::Activity",
                  order: Sequel.desc([:created_at, :id]),
                  key: :subject_id_int,
                  conditions: {subject_type: m.name},
                  read_only: true

    # Create a +Suma::Member::Activity+ on the receiver.
    #
    # @param message_name [String] Simple, unique slug to group the action.
    # @param actor [Suma::Member] The actor. Default to +Suma.request_user_and_admin+ admin.
    #   Fall back to the request member. If nil, raise +ArgumentError+.
    # @param action [String] See below.
    # @param prefix [String] See below.
    # @param summary [String] See below.
    #
    # Activity summary is calculated as:
    # - If summary is given, use it explicitly.
    # - If action and prefix are given, the summary looks like "<prefix><action>".
    # - If only action is given, the summary looks like "a@b.c peformed rolechange on Suma::Member[5]: <action>".
    # - If action is a Sequel model, use the form "class name[id]", or if action responds to a :name method,
    #   use "class name[id] 'name'".
    # - If only prefix is given, the summary looks like "<prefix>".
    # - If action nor prefix are given, the summary looks like "a@b.c peformed rolechange on Suma::Member[5]".
    m.define_method(:audit_activity) do |message_name, actor: nil, action: nil, prefix: nil, summary: nil|
      if actor.nil?
        user, admin = Suma.request_user_and_admin
        actor = actor || admin || user
      end
      raise ArgumentError, "actor must be provided or in the request" if actor.nil?
      if action.is_a?(Sequel::Model)
        action_model = action
        action = Suma::HasActivityAudit.model_repr(action_model)
      end
      if summary.nil?
        if action && prefix
          summary = "#{prefix}#{action}"
        elsif prefix
          summary = prefix
        else
          identifier = Suma::HasActivityAudit.model_repr(self)
          pre = "#{actor.email || actor.name} performed #{message_name} on #{identifier}"
          summary = action ? "#{pre}: #{action}" : pre
        end
      end
      activity = actor.add_activity(
        message_name:,
        summary:,
        subject_type: self.class.name,
        subject_id: self.id,
      )
      activity
    end
  end

  def self.model_repr(m)
    s = "#{m.class.name}[#{m.pk}]"
    return s unless m.respond_to?(:name)
    name = m.name
    name = name.send(SequelTranslatedText.default_language) if name.respond_to?(SequelTranslatedText.default_language)
    return s + " '#{name}'"
  end
end
