# frozen_string_literal: true

# Represents a 'thing' that can be presented to members
# in an offering context. This can be available offerings,
# but also
class Suma::Vendible < Suma::TypedStruct
  #
  # @return [Suma::TranslatedText]
  attr_accessor :name

  # @return [Time]
  attr_accessor :until

  # @return [Suma::Image]
  attr_accessor :image

  class << self
    # @param [Suma::Commerce::Offering] o
    # @return [Suma::Vendible]
    def from_commerce_offering(o)
      return self.new(
        name: o.description,
        until: o.period_end,
        image: o.image?,
      )
    end

    # @param [Suma::Vendor::Service] vs
    # @return [Suma::Vendible]
    def from_vendor_service(vs)
      return self.new(
        name: Suma::TranslatedText.new(all: vs.external_name).freeze,
        until: vs.period_end,
        image: vs.image?,
      )
    end

    def from(o)
      case o
        when Suma::Commerce::Offering
          self.from_commerce_offering(o)
        when Suma::Vendor::Service
          self.from_vendor_service(o)
        else
          raise TypeError, "unhandled vendible source type '#{o.class.name}': #{o}"
      end
    end
  end

  class Grouping < Suma::TypedStruct
    # @return [Suma::Vendible::Group]
    attr_accessor :group
    # @return [Array<Suma::Vendible>]
    attr_accessor :vendibles
  end

  # @param items [Array<Suma::Vendor::Service,Suma::Commerce::Offering>]
  # @return [Array<Array<Suma::Vendible::Grouping>]
  def self.groupings(items)
    grouped = {}
    items.each do |it|
      it.vendible_groups.each do |g|
        grouped[g.id] ||= Grouping.new(group: g, vendibles: [])
        grouped[g.id].vendibles << self.from(it)
      end
    end
    groupings = grouped.values.sort_by { |g| g.group.ordinal }
    groupings.each do |grping|
      grping.vendibles.sort_by! { |v| [v.name.en, v.until] }
    end
    return groupings
  end
end
