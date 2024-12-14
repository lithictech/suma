# frozen_string_literal: true

class Suma::Frontapp::ListSync
  def initialize(now:)
    @now = now
  end

  def run
    specs = self.gather_list_specs
    spec_names = specs.to_set(&:name)
    groups = Suma::Frontapp.client.contact_groups
    # The easiest way to bulk-replace all the contacts is to delete and recreate the group
    groups_to_replace = groups.select { |g| spec_names.include?(g.fetch("name")) }
    groups_to_replace.each do |group|
      Suma::Frontapp.client.delete_contact_group!(group.fetch("id"))
    end
    # Since create contact group does not return the ID, we create and then re-fetch
    specs.each do |spec|
      Suma::Frontapp.client.create_contact_group!(name: spec.name)
    end
    # Find the group we just created, and add all the contacts do it
    groups = Suma::Frontapp.client.contact_groups
    specs.each do |spec|
      existing_group = groups.find { |g| g.fetch("name") == spec.name }
      raise Suma::InvalidPostcondition, "cannot find the group we just created: #{spec.name}" if existing_group.nil?
      contact_ids = spec.dataset.select_map(:frontapp_contact_id)
      next if contact_ids.empty?
      Suma::Frontapp.client.add_contacts_to_contact_group!(existing_group.fetch("id"), {contact_ids:})
    end
  end

  def gather_list_specs
    result = []
    result << ListSpec.new(
      "SMS Marketing (English)",
      Suma::Member.where(preferences: Suma::Message::Preferences.where(
        marketing_sms_optout: false, preferred_language: "en",
      )),
    )
    result << ListSpec.new(
      "SMS Marketing (Spanish)",
      Suma::Member.where(preferences: Suma::Message::Preferences.where(
        marketing_sms_optout: false, preferred_language: "es",
      )),
    )
    return result
  end

  class ListSpec
    attr_reader :name, :dataset

    def initialize(name, dataset)
      @name = name
      @dataset = dataset.exclude(frontapp_contact_id: "")
    end
  end
end
