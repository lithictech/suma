# frozen_string_literal: true

require "suma/postgres/model"
require "suma/vendible"
require "suma/admin_linked"

# Displayable group of things that are 'sold'.
# This is usually things like grouping commerce offerings into 'Farmers Markets'.
# The Suma::Vendible.grouping method is used to group resources into their
# vendible groups.
#
# Note that vendible groups are just used for display purposes.
# So an valid offering that is not in a vendible group will still show up
# when fetching all offerings, but will not show up when fetching all vendible groups.
class Suma::Vendible::Group < Suma::Postgres::Model(:vendible_groups)
  include Suma::AdminLinked

  plugin :translated_text, :name, Suma::TranslatedText
  plugin :association_pks

  many_to_many :vendor_services,
               class: "Suma::Vendor::Service",
               join_table: :vendible_groups_vendor_services,
               left_key: :group_id,
               right_key: :service_id

  many_to_many :commerce_offerings,
               class: "Suma::Commerce::Offering",
               join_table: :vendible_groups_commerce_offerings,
               left_key: :group_id,
               right_key: :offering_id

  plugin :association_array_replacer, :vendor_services, :commerce_offerings

  # All the vendible items or goods for this group.
  # @return [Array<Suma::Vendible>]
  def vendibles
    vendibles = (self.commerce_offerings + self.vendor_services).map do |it|
      Suma::Vendible.from(it)
    end
    vendibles.sort_by! { |v| [v.name.en, v.until] }
    return vendibles
  end

  def rel_admin_link = "/vendible-group/#{self.id}"
end
