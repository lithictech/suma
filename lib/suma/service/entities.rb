# frozen_string_literal: true

require "grape_entity"
require "suma/i18n/formatter"

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
    def current_time = self.options.fetch(:env).fetch("now")

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

    def evaluate_exposure(name, block, instance, options)
      return instance.send(name) unless block
      return block.arity == 1 ? block[instance] : block[instance, options]
    end

    def self.expose_translated(name, *args, &block)
      self.expose(name, *args) do |instance, options|
        txt = self.evaluate_exposure(name, block, instance, options)
        s = txt&.string || ""
        i18n_fmt = Suma::I18n::Formatter.for(s)
        "#{i18n_fmt.flag}#{s}"
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
    expose :role_access, &self.delegate_to(:role_access, :as_json)
    protected def current_session
      env = options.fetch(:env)
      yosoy = env.fetch("yosoy")
      @current_session ||= yosoy.authenticated_object!
      return @current_session
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
