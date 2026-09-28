# frozen_string_literal: true

require "state_machines"

require "suma"

class Suma::StateMachine
  attr_reader :name, :machine

  def initialize(obj, name, admin_resource)
    @obj = obj
    @name = name
    @admin_prefix = "/adminapi/v1/#{admin_resource}/#{obj.id}"
    @machine = @obj.class.state_machines[@name]
  end

  def current_state = @obj.send(@name)

  # @return [Array<Symbol>]
  def available_events = @machine.events.valid_for(@obj).map(&:name)

  # Return {name, label:, url:} hashes for each event.
  # The URL is the POST location to POST to process the state machine.
  # @return [Array<Hash>]
  def available_processing
    return self.available_events.map do |name|
      {name:, label: name.to_s.titlecase, url: "#{@admin_prefix}/state_machines/#{self.name}/#{name}"}
    end
  end
end
