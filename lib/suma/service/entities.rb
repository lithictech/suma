# frozen_string_literal: true

require "grape_entity"

module Suma::Service::Entities
  class Money < Grape::Entity
    expose :cents
    expose :currency do |obj|
      obj.currency.iso_code
    end
  end

  class TimeRange < Grape::Entity
    expose :begin, as: :start
    expose :end
  end

  class Base < Grape::Entity
    extend Suma::MethodUtilities

    expose :object_type, as: :object, unless: ->(_, _) { self.object_type.nil? }

    # Override this on entities that are addressable on their own
    def object_type
      return nil
    end

    def self.timezone(*lookup_path, field: nil)
      return lambda do |instance, opts|
        field ||= opts[:attr_path].last
        tz = lookup_path.reduce(instance) do |memo, name|
          memo.send(name)
        rescue NoMethodError
          nil
        end
        t = instance.send(field)
        if tz.blank?
          t
        else
          tz = tz.timezone if tz.respond_to?(:timezone)
          tz = tz.time_zone if tz.respond_to?(:time_zone)
          t.in_time_zone(tz).iso8601
        end
      end
    end

    def self.delegate_to(*names, safe: false, safe_with_default: nil)
      return lambda do |instance|
        names.reduce(instance) do |memo, name|
          memo.send(name)
        rescue NoMethodError => e
          return safe_with_default unless safe_with_default.nil?
          return nil if safe
          raise e
        end
      end
    end
  end

  class Image < Base
    expose :url
    expose :alt
  end

  class Address < Base
    expose :address1
    expose :address2
    expose :city
    expose :state_or_province
    expose :postal_code
    expose :country
    expose :lat
    expose :lng
  end

  class CurrentMember < Base
    expose :id
    expose :created_at
    expose :email
    expose :name
    expose :us_phone, as: :phone
    expose :onboarded?, as: :onboarded
    expose :roles do |instance|
      instance.roles.map(&:name)
    end
    protected def impersonation
      return @impersonation ||= Suma::Service::Auth::Impersonation.new(options[:env]["warden"])
    end
  end

  class LegalEntityEntity < Base
    expose :id
    expose :name
    expose :address, with: Address, safe: true
  end

  # Add an 'etag' field to the rendered entity.
  # This should only be used on the root entity, and entities with etags should not be nested.
  # Usage:
  #
  #   class DashboardEntity < BaseEntity
  #     prepend Suma::Service::Entities::EtaggedMixin
  #     expose :my_field
  #   end
  module EtaggedMixin
    def to_json(*)
      serialized = super
      raise TypeError, "EtaggedMixin can only be used for object entities" unless serialized[-1] == "}"
      etag = Digest::MD5.hexdigest(Suma::VERSION.to_s + serialized)
      return serialized[...-1] + ",\"etag\":\"#{etag}\"}"
    end
  end
end
