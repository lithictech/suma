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
      external_id_col = @component.external_id_column
      insert = rows.first.each_key.to_h { |c| [c, c] }
      update = rows.first.each_key.to_h { |c| [c, Sequel[source_alias][c]] }
      update.delete(external_id_col)
      @component.model.dataset.
        merge_using(
          Sequel.as(
            @component.model.dataset.db.values(rows.map(&:values)),
            source_alias,
            rows.first.keys,
          ),
          Sequel[@component.model.table_name][external_id_col] => Sequel[source_alias][external_id_col],
        ).
        merge_update(update).
        merge_insert(insert).
        merge
      found_ids = rows.map { |r| r[external_id_col] }
      # Use MERGE WHEN NOT MATCHED BY SOURCE in Postgres 17 when available, after late 2024
      @component.model.where(vendor_service: @mobility_services).exclude(external_id_col => found_ids).delete
    end
    return rows.length
  end
end
