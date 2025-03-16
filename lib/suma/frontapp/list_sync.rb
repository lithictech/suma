# frozen_string_literal: true

require "appydays/loggable"

class Suma::Frontapp::ListSync
  include Appydays::Loggable

  RECENTLY_UNVERIFIED_CUTOFF_DAYS = 30

  def initialize(now:)
    @now = now
  end

  def run
    specs = self.gather_list_specs
    spec_names = specs.to_set(&:full_name)
    groups = Suma::Frontapp.client.contact_groups
    # The easiest way to bulk-replace all the contacts is to delete and recreate the group
    groups_to_replace = groups.select { |g| spec_names.include?(g.fetch("name")) }
    groups_to_replace.each do |group|
      self.logger.info("deleting_front_group", group_id: group.fetch("id"), group_name: group.fetch("name"))
      Suma::Frontapp.client.delete_contact_group!(group.fetch("id"))
    end
    specs_with_members = specs.reject { |sp| sp.dataset.empty? }
    # Since create contact group does not return the ID, we create and then re-fetch
    specs_with_members.each do |spec|
      self.logger.info("creating_front_contact_group", group_name: spec.full_name)
      Suma::Frontapp.client.create_contact_group!(name: spec.full_name)
    end
    # Find the group we just created, and add all the contacts do it
    groups = Suma::Frontapp.client.contact_groups
    self.logger.info("listed_front_contact_groups", group_count: groups.count)
    specs_with_members.each do |spec|
      existing_group = groups.find { |g| g.fetch("name") == spec.full_name }
      raise Suma::InvalidPostcondition, "cannot find the group we just created: #{spec.full_name}" if
        existing_group.nil?
      contact_ids = spec.dataset.select_map(:phone).map { |p| Suma::Frontapp.contact_alt_handle(:phone, p) }
      next if contact_ids.empty?
      self.logger.info(
        "updating_front_contact_group",
        group_id: existing_group.fetch("id"),
        group_name: existing_group.fetch("name"),
        contact_ids: contact_ids.size,
      )
      contact_ids.each_slice(300) do |slice|
        Suma::Frontapp.client.add_contacts_to_contact_group!(existing_group.fetch("id"), {contact_ids: slice})
      end
    end
  end

  def gather_list_specs
    result = []
    result.concat(
      ListSpec.for_languages(
        name: "Marketing",
        transport: :sms,
        dataset: Suma::Member.where(preferences: Suma::Message::Preferences.where(marketing_sms_optout: false)),
      ),
    )
    result.concat(
      ListSpec.for_languages(
        name: "Unverified, last #{RECENTLY_UNVERIFIED_CUTOFF_DAYS} days",
        transport: :sms,
        dataset: Suma::Member.
          where { created_at > RECENTLY_UNVERIFIED_CUTOFF_DAYS.days.ago }.
          where(onboarding_verified_at: nil),
      ),
    )
    result.concat(
      ListSpec.for_languages(
        name: "Unverified, All time",
        transport: :sms,
        dataset: Suma::Member.where(onboarding_verified_at: nil),
      ),
    )
    Suma::Organization.all.each do |org|
      result.concat(
        ListSpec.for_languages(
          name: org.name,
          transport: :sms,
          dataset: Suma::Member.where(organization_memberships: org.memberships_dataset),
        ),
      )
    end
    return result
  end

  class ListSpec < Suma::TypedStruct
    attr_reader :name, :transport, :language, :dataset

    def self.for_languages(**kw)
      return Suma::I18n::SUPPORTED_LOCALES.values.map do |locale|
        self.new(language: locale.code, **kw)
      end
    end

    def initialize(**kw)
      super
      preferences_ds = Suma::Message::Preferences.where(
        "#{self.transport}_enabled": true, preferred_language: self.language,
      )
      @dataset = self.dataset.
        not_soft_deleted.
        where(preferences: preferences_ds)
    end

    def full_name
      lang = Suma::I18n::SUPPORTED_LOCALES.fetch(self.language).language
      "#{self.name} - #{self.transport.to_s.upcase} - #{lang}"
    end
  end
end
