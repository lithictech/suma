# frozen_string_literal: true

require "suma/marketing"
require "suma/postgres/model"

class Suma::Marketing::List < Suma::Postgres::Model(:marketing_lists)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked

  plugin :hybrid_search
  plugin :timestamps

  many_to_many :members,
               class: "Suma::Member",
               join_table: :marketing_lists_members,
               left_key: :marketing_list_id,
               right_key: :member_id

  class << self
    # Rebuild the managed list specification (replace all members).
    # @param spec [Specification]
    def rebuild(spec)
      self.db.transaction do
        list = self.find_or_create(label: spec.full_label, managed: true)
        # Use MERGE WHEN NOT MATCHED BY SOURCE in Postgres 17 when available, after late 2024
        self.db[:marketing_lists_members].
          where(marketing_list_id: list.id).
          exclude(member_id: spec.members_dataset.select(:id)).
          delete
        list_id = list.id
        self.db[:marketing_lists_members].
          insert_conflict.
          import([:marketing_list_id, :member_id], spec.members_dataset.select { [list_id, id] })
        return list
      end
    end

    # Rebuild all of the given specifications. Delete any managed lists that are not present in +specs+.
    def rebuild_all(*specs)
      lists = specs.map { |sp| self.rebuild(sp) }
      self.where(managed: true).exclude(id: lists.map(&:id)).delete
      return lists
    end
  end

  def rel_admin_link = "/marketing-list/#{self.id}"

  def hybrid_search_fields
    return [
      :label,
      :managed,
    ]
  end

  class Specification < Suma::TypedStruct
    attr_reader :label, :transport, :language, :members_dataset

    def initialize(**kw)
      super
      preferences_ds = Suma::Message::Preferences.where(
        "#{self.transport}_enabled": true, preferred_language: self.language,
      )
      @members_dataset = self.members_dataset.
        not_soft_deleted.
        where(preferences: preferences_ds)
    end

    def full_label
      lang = Suma::I18n::SUPPORTED_LOCALES.fetch(self.language).language
      "#{self.label} - #{self.transport.to_s.upcase} - #{lang}"
    end

    def self.for_languages(**kw)
      return Suma::I18n::SUPPORTED_LOCALES.values.map do |locale|
        self.new(language: locale.code, **kw)
      end
    end

    RECENTLY_UNVERIFIED_CUTOFF_DAYS = 30

    def self.gather_all
      result = []
      result.concat(
        self.for_languages(
          label: "Marketing",
          transport: :sms,
          members_dataset: Suma::Member.
            where(preferences: Suma::Message::Preferences.where(marketing_sms_optout: false)),
        ),
      )
      result.concat(
        self.for_languages(
          label: "Unverified, last #{RECENTLY_UNVERIFIED_CUTOFF_DAYS} days",
          transport: :sms,
          members_dataset: Suma::Member.
            where { created_at > RECENTLY_UNVERIFIED_CUTOFF_DAYS.days.ago }.
            where(onboarding_verified_at: nil),
        ),
      )
      result.concat(
        self.for_languages(
          label: "Unverified, All time",
          transport: :sms,
          members_dataset: Suma::Member.where(onboarding_verified_at: nil),
        ),
      )
      Suma::Organization.all.each do |org|
        result.concat(
          self.for_languages(
            label: org.name,
            transport: :sms,
            members_dataset: Suma::Member.where(organization_memberships: org.memberships_dataset),
          ),
        )
      end
      return result
    end
  end
end
