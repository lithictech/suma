# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceCategory < Suma::Postgres::Model(:vendor_service_categories)
  include TSort
  many_to_many :services,
               class: "Suma::Vendor::Service",
               join_table: :vendor_service_categories_vendor_services,
               left_key: :category_id,
               right_key: :service_id
  many_to_one :parent, class: self
  one_to_many :children, class: self, key: :parent_id

  # TSort API: Iterate self and children to go through entire graph.
  def tsort_each_node(&)
    yield(self)
    self.children.each do |c|
      c.tsort_each_node(&)
    end
  end

  def tsort_each_child(node, &)
    return node.children.each(&)
  end

  def hierarchy_depth
    d = 0
    it = self
    while (parent = it.parent)
      d += 1
      it = parent
    end
    return d
  end

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end
end
