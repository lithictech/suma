# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Image < Suma::Postgres::Model(:images)
  plugin :timestamps
  plugin :soft_deletes

  many_to_one :commerce_offering, class: "Suma::Commerce::Offering"
  many_to_one :commerce_product, class: "Suma::Commerce::Product"
  many_to_one :uploaded_file, class: "Suma::UploadedFile"

  class << self
    def no_image_available
      return @no_image_available if @no_image_available
      @no_image_available = self.new(ordinal: 0, caption: "")
      @no_image_available.associations[:uploaded_file] = Suma::UploadedFile::NoImageAvailable.new
      @no_image_available.freeze
      return @no_image_available
    end
  end

  module AssociatedMixin
    def self.included(m)
      key = m.name.gsub("Suma::", "").gsub("::", "_").underscore + "_id"
      m.one_to_many :images, key: key.to_sym, class: "Suma::Image", order: [:ordinal, :id]
      m.define_method(:images?) do
        if self.images.empty?
          [Suma::Image.no_image_available]
        else
          self.images
        end
      end
    end
  end
end
