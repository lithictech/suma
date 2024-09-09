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
      # TODO: values must be passed as (1, 2), (3, 8) but the lit method converts array to ((1, 2), (3, 8))
      # This merge execution will fail, needs to be formatted correctly. The advantage of using `.lit`
      # is that row values are automatically formatted correctly, take this as example:
      # {"web" => "https://abc.com"} -> '{"web": "https://abc.com"}'::jsonb
      # The other alternative for merge_using +source+ is to build a temporary table
      @component.model.dataset.
        merge_using(
          Sequel.as(
            Sequel.lit("VALUES ?", rows.map(&:values)).with_parens,
            source_alias,
            rows.first.keys,
          ),
          Sequel[@component.model.table_name][@component.id_column] => Sequel[source_alias][@component.id_column],
        ).
        merge_insert(insert).
        merge_update(update).
        merge
    end
    return rows.length
  end
end
