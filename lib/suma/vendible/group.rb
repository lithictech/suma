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

  def replace_commerce_offerings(offerings)
    self.replace_association_models(offerings, :commerce_offerings)
  end

  def replace_vendor_services(services)
    self.replace_association_models(services, :vendor_services)
  end

  def replace_association_models(models, assoc_name)
    self.db.transaction do
      model_ids = models.map(&:id)
      assoc_ref = self.class.association_reflections.fetch(assoc_name)
      assoc_class = assoc_ref.fetch(:class_name).constantize
      assoc_dataset = self.send(assoc_ref.fetch(:dataset_method))

      to_remove = assoc_dataset.exclude(id: model_ids)
      to_add = assoc_class.where(id: model_ids).exclude(id: assoc_dataset.select(:id))
      to_add.each { |model| self.send(assoc_ref.fetch(:add_method), model) }
      to_remove.each { |model| self.send(assoc_ref.fetch(:remove_method), model) }
    end
  end

  def rel_admin_link = "/vendible-group/#{self.id}"
end
