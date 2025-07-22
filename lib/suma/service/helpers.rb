# -*- ruby -*-
# frozen_string_literal: true

require "appydays/loggable"
require "grape"

require "suma/service" unless defined?(Suma::Service)
require "suma/service/collection"

# A collection of helper functions that can be included
module Suma::Service::Helpers
  extend Grape::API::Helpers
  include Suma::Service::Collection::Helpers

  def logger
    return Suma::Service.logger
  end

  # Error if there is already an authed user.
  def guard_authed!
    merror!(409, "You are already signed in. Please sign out first.", code: "auth_conflict") if
      current_member?
  end

  def current_time = env.fetch("now")

  def rack_session = env.fetch("rack.session")
  # @return [Suma::Yosoy::Proxy]
  def yosoy = env.fetch("yosoy")
  # @return [String]
  def current_session_id = rack_session.session_id
  # @return [Suma::Member::Session]
  def current_session = yosoy.authenticated_object!
  # @return [Suma::Member::Session,nil]
  def current_session? = yosoy.authenticated_object?

  # Return the currently-authenticated user,
  # or respond with a 401 if there is no authenticated user.
  # @return [Suma::Member]
  def current_member
    m = current_member?
    unauthenticated! unless m
    return m
  end

  # Return the currently-authenticated user,
  # or respond nil if there is no authenticated user.
  # @return [Suma::Member,nil]
  def current_member?
    return nil unless (cs = current_session?)
    if cs.impersonation?
      unauthenticated! unless cs.member.role_access { read?(impersonate) }
      return cs.impersonating
    end
    unauthenticated! if cs.member.soft_deleted?
    return cs.member
  end

  # @return [Suma::Member]
  def admin_member
    m = admin_member?
    unauthenticated! unless m
    return m
  end

  # @return [Suma::Member,nil]
  def admin_member?
    return nil unless (cs = current_session?)
    m = cs.member
    return nil unless m.role_access { read?(admin_access) }
    unauthenticated! if m.soft_deleted?
    return m
  end

  def logout
    current_session?&.mark_logged_out&.save_changes
    options = env[Rack::RACK_SESSION_OPTIONS]
    options[:drop] = true

    # Rack sends a cookie with an empty session, but let's tell the browser to actually delete the cookie.
    cookies.delete(Suma::Service::SESSION_COOKIE, domain: options[:domain], path: options[:path])
    # Set this header to tell the client to delete everything.
    header "Clear-Site-Data", "*"
  end

  def set_session(session)
    yosoy.set_authenticated_object(session)
  end

  def unauthenticated!
    yosoy.unauthenticated!
  end

  def check_role_access!(member, rw, key)
    return if member.role_access.can?(rw, key)
    merror!(403, "You are not permitted to #{rw} on #{key}", code: "role_check")
  end

  def merror!(status, message, code:, more: {}, skip_loc_check: false)
    if !skip_loc_check && !Suma::Service.error_code_localized?(code)
      merror!(500, "Error code is unlocalized: #{code}", code: "unhandled_error")
    end
    header Rack::CONTENT_TYPE, "application/json"
    body = Suma::Service.error_body(status, message, code:, more:)
    error!(body, status)
  end

  def adminerror!(status, message, code: "admin", more: {})
    merror!(status, message, code:, more:, skip_loc_check: true)
  end

  def forbidden!(message="Forbidden")
    merror!(403, message, code: "forbidden")
  end

  def invalid!(errors, message: nil)
    errors = [errors] unless errors.respond_to?(:to_ary)
    message ||= errors.join(", ")
    message = message.first.upcase + message[1..]
    merror!(400, message, code: "validation_error", more: {errors:})
  end

  def search_param_to_sql(params, column, param: :search)
    return search_to_sql(params[param]&.strip, column)
  end

  def search_to_sql(search_value, column)
    return nil if search_value.blank? || search_value == "*"
    term = "%#{search_value.strip}%"
    return Sequel.ilike(column, term)
  end

  ### If +object+ is valid, save and return it.
  ### If not, call invalid! witht the validation errors.
  def save_or_error!(object)
    if object.valid?
      object.save_changes
      return object
    else
      invalid!(object.errors.full_messages)
    end
  end

  def paginate(dataset, params)
    return dataset.paginate(params[:page], params[:per_page])
  end

  # Order the database. By default, use descending nulls last.
  # If order_direction is :asc, use ascending nulls first.
  def order(dataset, params, disambiguator: Sequel[dataset.model.table_name][dataset.model.primary_key])
    if params[:order_direction] == :asc
      m = :asc
      nulls = :first
    else
      nulls = :last
      m = :desc
    end
    expr = Sequel.send(m, params[:order_by], nulls:)
    return dataset.order(expr, Sequel.desc(disambiguator))
  end

  # Return true if the key was passed in the GET query params
  # or POST body. false if not passed.
  # This is the only way to know if a param was passed,
  # rather than set by a default value in a Grape parameter block.
  # `params` and `declared` include default parameterw.
  def param_passed?(key)
    key = key.to_s
    return request.GET.key?(key) || request.POST.key?(key)
  end

  def hybrid_search(dataset, params)
    search = params.fetch(:search)
    # Convert US-formatted phone numbers to E164 format (no leading country code)
    # so they can be matched more explicitly. Otherwise, the spaces in the phone number
    # are split as tokens, and we get bad results.
    search = search.gsub(/\(\d\d\d\) \d\d\d-\d\d\d\d/) do |match|
      match.gsub(/\D/, "")
    end
    return dataset.hybrid_search(search)
  end

  def use_http_expires_caching(expiration)
    return unless Suma::Service.endpoint_caching
    header "Cache-Control", "public"
    header "Expires", expiration.from_now.httpdate
  end

  # Set the provided, declared/valid parameters in params on model.
  # Because Grape's `declared()` function *adds* parameters that are declared-but-not-provided,
  # and its `params` value includes provided-but-not-declared entries,
  # the fields we set are the intersection of the two.
  def set_declared(model, params, ignore: [:id])
    # If .to_h is used (rather than Grape's 'params' which is HashWithIndifferentAccess),
    # the keys may be strings. We need to deep symbolize since nested hashes get to_h with 'symbolize_keys'.
    params = params.deep_symbolize_keys
    decl = declared_and_provided_params(params, exclude: ignore)
    ignore.each { |k| decl.delete(k) }
    decl.delete_if { |k| !params.key?(k) }
    model.set(decl)
  end

  def declared_and_provided_params(params, exclude: [])
    params = params.deep_dup
    decl = declared(params)
    exclude.each { |k| decl.delete(k) }
    _remove_provided_keys_not_declared(params, decl)
    return params
  end

  # Given the provided params, remove any keys that aren't declared.
  # We know at this point the hashes have a consistent structure (in terms of hash and array keys)
  # because of Grape's validation; but we need to, for example, make sure:
  # - Only provided params are used (declared will have a field for every parameter)
  # - If x:nil is passed for a JSON param, x:nil is used. declared may have x:{id:nil, name:nil}, etc.
  private def _remove_provided_keys_not_declared(provided, declared)
    # noinspection RubyCaseWithoutElseBlockInspection
    case provided
      when Hash
        provided.each_key do |key|
          if declared.key?(key)
            _remove_provided_keys_not_declared(provided[key], declared[key])
          else
            provided.delete(key)
          end
        end
      when Array
        # We know these are the same length since declared is based on provided params.
        provided.each_with_index do |provided_item, idx|
          _remove_provided_keys_not_declared(provided_item, declared[idx])
        end
    end
  end

  params :money do
    requires :cents, type: Integer
    optional :currency, type: String, default: "USD"
  end

  params :funding_money do
    use :money
    requires :cents,
             type: Integer,
             values: {
               value: ->(v) { v >= Suma::Payment.minimum_funding_amount_cents },
               message: "must be at least #{Suma::Payment.minimum_funding_amount_cents}",
             }
  end

  params :pagination do
    optional :page, type: Integer, default: 1, values: (1..1_000_000)
    optional :per_page, type: Integer, default: Suma::Service::PAGE_SIZE, values: (1..500)
  end

  params :short_pagination do
    optional :page, type: Integer, default: 1, values: (1..1_000_000)
    optional :per_page, type: Integer, default: Suma::Service::SHORT_PAGE_SIZE, values: (1..50)
  end

  params :searchable do
    optional :search, type: String
  end

  params :ordering do |options|
    default_order_by = options.key?(:default) ? options[:default] : :created_at
    order_by_values = options[:values] || options[:model]&.columns
    raise "Must provide :values or :model for possible orderings" unless order_by_values
    optional :order_by, type: Symbol, values: order_by_values, default: default_order_by
    optional :order_direction, type: Symbol, values: [:asc, :desc], default: :desc
  end

  params :address do
    optional :address1, type: String, allow_blank: false
    optional :address2, type: String
    optional :city, type: String, allow_blank: false
    optional :state_or_province, type: String, allow_blank: false
    optional :postal_code, type: String, allow_blank: false
    all_or_none_of :address1, :city, :state_or_province, :postal_code
    optional :lat, type: Float
    optional :lng, type: Float
  end

  params :translated_text do |options|
    blank = options[:allow_blank] || false || options[:optional]
    meth = options[:optional] ? :optional : :requires
    send(meth, :en, type: String, allow_blank: blank)
    send(meth, :es, type: String, allow_blank: blank)
  end

  params :model_with_id do
    requires :id, type: Integer
  end

  params :payment_instrument do
    requires :payment_instrument_id, type: Integer
    requires :payment_method_type, type: String, values: ["bank_account", "card"]
  end

  def find_payment_instrument?(member, params)
    return nil if params.nil?
    return nil unless params[:payment_instrument_id]
    return find_payment_instrument!(member, params)
  end

  def find_payment_instrument!(member, params)
    instrument = member.usable_payment_instruments.find do |pi|
      pi.id == params[:payment_instrument_id] && pi.payment_method_type == params[:payment_method_type]
    end
    merror!(403, "Instrument not found", code: "resource_not_found") unless instrument
    return instrument
  end
end
