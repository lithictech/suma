# frozen_string_literal: true

class Suma::Program::Component < Suma::TypedStruct
  # @return [Suma::TranslatedText]
  attr_accessor :name

  # @return [Time]
  attr_accessor :until

  # @return [Suma::Image]
  attr_accessor :image

  # @return [String] relative app link
  attr_accessor :link

  class << self
    # @param [Suma::Commerce::Offering] o
    # @return [Suma::Program::Component]
    def from_commerce_offering(o)
      return self.new(
        name: o.description,
        until: o.period_end,
        image: o.image?,
        link: o.rel_app_link,
      )
    end

    # @param [Suma::Vendor::Service] vs
    # @return [Suma::Program::Component]
    def from_vendor_service(vs)
      return self.new(
        name: Suma::TranslatedText.new(all: vs.external_name).freeze,
        until: vs.period_end,
        image: vs.image?,
        link: vs.rel_app_link,
      )
    end

    # @param [Suma::AnonProxy::VendorConfiguration] vc
    # @return [Suma::Program::Component]
    def from_anon_proxy_vendor_configuration(vc)
      return self.new(
        name: Suma::TranslatedText.new(all: vc.vendor.name).freeze,
        until: nil,
        image: vc.vendor.image?,
        link: "/private-accounts",
      )
    end

    def from(o)
      case o
        when Suma::Commerce::Offering
          self.from_commerce_offering(o)
        when Suma::Vendor::Service
          self.from_vendor_service(o)
        when Suma::AnonProxy::VendorConfiguration
          self.from_anon_proxy_vendor_configuration(o)
        else
          raise TypeError, "unhandled vendible source type '#{o.class.name}': #{o}"
      end
    end
  end
end
