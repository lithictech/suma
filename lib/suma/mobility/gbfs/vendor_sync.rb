# frozen_string_literal: true

class Suma::Mobility::Gbfs::VendorSync
  attr_reader :client, :vendor, :component

  # @param client [Suma::Mobility::Gbfs::BaseClient]
  def initialize(client:, vendor:, component:)
    @client = client
    @vendor = vendor
    @mobility_services = vendor.services_dataset.mobility.all
    @component = component
  end

  def sync_all
    @component.before_sync(@client)
    rows = []
    @mobility_services.each do |vs|
      @component.yield_rows(vs) { |r| rows << r }
    end
    @component.model.db.transaction do
      if rows.empty?
        @component.model.where(vendor_service: @mobility_services).delete
        return 0
      end
      source_alias = :source
      insert = {}
      update = {}
      rows.first.each_key { |c| insert[c] = c }
      @component.sync_columns.each { |c| update[c] = Sequel[source_alias][c] }
      @component.model.dataset.
        merge_using(
          Sequel.as(
            Sequel.lit(["VALUES ", *Array.new(rows.count - 1) { "," }], *rows.map(&:values)).with_parens,
            source_alias,
            rows.first.keys,
          ),
          Sequel[@component.model.table_name][:id] => Sequel[source_alias][:id],
        ).
        merge_update(update).
        merge_insert(insert).
        merge
    end
    return rows.length
  end
end
