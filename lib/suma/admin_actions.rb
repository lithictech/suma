# frozen_string_literal: true

# Helper for classes that define admin_actions.
# Implementers should override +_admin_actions_self+.
# Every item should be nil, or a +Suma::AdminActions::Action+ instance.
# The response value of the action is displayed in the admin UI.
module Suma::AdminActions
  class Action < Suma::TypedStruct
    attr_reader :label, :url, :params

    def _defaults = {params: {}}
  end

  def admin_actions = _admin_actions_self
  # @return [Array<Action>]
  def _admin_actions_self = raise NotImplementedError
  def _admin_action(label, url, params: {}) = Action.new(label:, url:, params:)
end
