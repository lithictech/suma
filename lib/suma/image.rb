# frozen_string_literal: true

require "suma/postgres/model"
require "suma/translated_text"

class Suma::Image < Suma::Postgres::Model(:images)
  plugin :timestamps
  plugin :soft_deletes
  plugin :translated_text, :caption, Suma::TranslatedText

  many_to_one :uploaded_file, class: "Suma::UploadedFile"

  # Associated objects
  many_to_one :commerce_offering, class: "Suma::Commerce::Offering"
  many_to_one :commerce_product, class: "Suma::Commerce::Product"
  many_to_one :vendor, class: "Suma::Vendor"
  many_to_one :vendor_service, class: "Suma::Vendor::Service"
  many_to_one :program, class: "Suma::Program"
  many_to_one :mobility_trip, class: "Suma::Mobility::Trip"

  def associated_object
    return self.commerce_product || self.commerce_offering || self.vendor_service || self.vendor || self.program
  end

  def associated_object=(o)
    self.commerce_offering = nil
    self.commerce_product = nil
    self.vendor = nil
    self.vendor_service = nil
    self.program = nil
    case o
        when nil
          nil
        when Suma::Commerce::Offering
          self.commerce_offering = o
        when Suma::Commerce::Product
          self.commerce_product = o
        when Suma::Vendor
          self.vendor = o
        when Suma::Vendor::Service
          self.vendor_service = o
        when Suma::Program
          self.program = o
      else
          raise TypeError, "invalid associated object type: #{o}"
      end
  end

  def validate
    super
    validates_presence :uploaded_file_id
    return unless !self.errors[:uploaded_file_id] && (self.new? || self.changed_columns.include?(:uploaded_file_id))
    # If we have an uploaded file, and our model is new, or the uploaded file has changed,
    # verify it is indeed an image.
    mt = MimeMagic.by_magic(self.uploaded_file.blob_stream_unsafe)
    self.errors.add(:uploaded_file, "is not an image") unless mt&.image?
  end

  class << self
    def no_image_available
      return @no_image_available if @no_image_available
      @no_image_available = self.new(ordinal: 0)
      @no_image_available.associations[:uploaded_file] = Suma::UploadedFile::NoImageAvailable.new
      @no_image_available.freeze
      return @no_image_available
    end
  end

  module AssociatedMixin
    def self.included(m)
      key_rel = m.name.gsub("Suma::", "").gsub("::", "_").underscore.to_sym
      key_col = :"#{key_rel}_id"
      m.one_to_many :images, key: key_col, class: "Suma::Image", order: [:ordinal, :id]
      m.define_singleton_method(:images_reverse_association_name) { key_rel }
      m.define_singleton_method(:images_reverse_association_column) { key_col }
      m.define_method(:images?) do
        if self.images.empty?
          [Suma::Image.no_image_available]
        else
          self.images
        end
      end
      m.define_method(:image?) do
        self.images.first || Suma::Image.no_image_available
      end
    end
  end

  # Mixin for models that should only have a single image.
  # The difference from +AssociatedMixin+ is that there is an +image+ accessor
  # (which will return the first image),
  # and the +image=+ accessor will destroy any existing image.
  module SingleAssociatedMixin
    def self.included(m)
      m.include(AssociatedMixin)
      m.one_to_one :image,
                   key: m.images_reverse_association_column,
                   class: "Suma::Image",
                   order: [:ordinal, :id],
                   read_only: true
      m.define_method(:image=) do |im|
        # We want to save the image to make setting the one-to-one simpler.
        im.update(m.images_reverse_association_name => self)
        # Delete all the existing images other than what we've set
        self.images_dataset.exclude(id: im.id).delete
        # Set the cached values, including the array which we know now has just one item
        self.associations[:images] = [im]
        self.associations[:image] = im
        im
      end
    end
  end
end

# Table: images
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                   | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at           | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at           | timestamp with time zone |
#  soft_deleted_at      | timestamp with time zone |
#  ordinal              | double precision         | NOT NULL DEFAULT 0
#  uploaded_file_id     | integer                  | NOT NULL
#  commerce_product_id  | integer                  |
#  commerce_offering_id | integer                  |
#  caption_id           | integer                  | NOT NULL
#  vendor_id            | integer                  |
#  vendor_service_id    | integer                  |
#  program_id           | integer                  |
#  mobility_trip_id     | integer                  |
# Indexes:
#  images_pkey                       | PRIMARY KEY btree (id)
#  images_commerce_offering_id_index | btree (commerce_offering_id)
#  images_commerce_product_id_index  | btree (commerce_product_id)
#  images_mobility_trip_id_index     | btree (mobility_trip_id)
#  images_program_id_index           | btree (program_id)
#  images_vendor_id_index            | btree (vendor_id)
#  images_vendor_service_id_index    | btree (vendor_service_id)
# Check constraints:
#  unambiguous_relation | (commerce_product_id IS NOT NULL AND commerce_offering_id IS NULL AND vendor_id IS NULL AND vendor_service_id IS NULL AND program_id IS NULL AND mobility_trip_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NOT NULL AND vendor_id IS NULL AND vendor_service_id IS NULL AND program_id IS NULL AND mobility_trip_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NULL AND vendor_id IS NOT NULL AND vendor_service_id IS NULL AND program_id IS NULL AND mobility_trip_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NULL AND vendor_id IS NULL AND vendor_service_id IS NOT NULL AND program_id IS NULL AND mobility_trip_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NULL AND vendor_id IS NULL AND vendor_service_id IS NULL AND program_id IS NOT NULL AND mobility_trip_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NULL AND vendor_id IS NULL AND vendor_service_id IS NULL AND program_id IS NULL AND mobility_trip_id IS NOT NULL)
# Foreign key constraints:
#  images_caption_id_fkey           | (caption_id) REFERENCES translated_texts(id)
#  images_commerce_offering_id_fkey | (commerce_offering_id) REFERENCES commerce_offerings(id)
#  images_commerce_product_id_fkey  | (commerce_product_id) REFERENCES commerce_products(id)
#  images_mobility_trip_id_fkey     | (mobility_trip_id) REFERENCES mobility_trips(id)
#  images_program_id_fkey           | (program_id) REFERENCES programs(id)
#  images_uploaded_file_id_fkey     | (uploaded_file_id) REFERENCES uploaded_files(id)
#  images_vendor_id_fkey            | (vendor_id) REFERENCES vendors(id)
#  images_vendor_service_id_fkey    | (vendor_service_id) REFERENCES vendor_services(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
