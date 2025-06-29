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
      actor ||= Suma.request_user_and_admin.last
      raise ArgumentError, "actor must be provided or in the request" if actor.nil?
      if action.is_a?(Sequel::Model)
        action_model = action
        action = "#{action_model.class.name}[#{action_model.pk}]"
        action += " '#{action_model.name}'" if action_model.respond_to?(:name)
      end
      if summary.nil?
        if action && prefix
          summary = "#{prefix}#{action}"
        elsif prefix
          summary = prefix
        else
          identifier = "#{self.class.name}[#{self.pk}]"
          identifier += " '#{self.name}'" if self.respond_to?(:name)
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
end
