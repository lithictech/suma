# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:map_locations) do
      primary_key :id
      numeric :lat, null: false
      numeric :lng, null: false
      unique [:lat, :lng]
    end
    create_join_table(
      {map_location_id: :map_locations, offering_id: :commerce_offerings},
      name: :map_locations_commerce_offerings,
    )
  end

  down do
    drop_table(:map_locations)
    drop_table(:map_locations_commerce_offerings)
  end
end
