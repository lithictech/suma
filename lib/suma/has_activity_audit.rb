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

    # Create a +Suma::Member::Activity+ on the given +member+ operating on the receiver as subject.
    #
    # Activity summary is calculated as:
    # - If summary is given, use it explicitly.
    # - If action and prefix are given, the summary looks like "<prefix><action>".
    # - If only action is given, the summary looks like "a@b.c peformed rolechange on Suma::Member[5]: <action>".
    # - If only prefix is given, the summary looks like "<prefix>".
    # - If action nor prefix are given, the summary looks like "a@b.c peformed rolechange on Suma::Member[5]".
    m.define_method(:audit_activity) do |message_name, member:, action: nil, prefix: nil, summary: nil|
      if summary.nil?
        if action && prefix
          summary = "#{prefix}#{action}"
        elsif prefix
          summary = prefix
        else
          pre = "#{member.email || member.name} performed #{message_name} on #{self.class.name}[#{self.pk}]"
          summary = action ? "#{pre}: #{action}" : pre
        end
      end
      activity = member.add_activity(
        message_name:,
        summary:,
        subject_type: self.class.name,
        subject_id: self.id,
      )
      activity
    end
  end
end
