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

  def guard_authed!
    merror!(409, "You are already signed in. Please sign out first.", code: "auth_conflict") if
      current_member?
  end

  # Return the currently-authenticated user,
  # or respond with a 401 if there is no authenticated user.
  def current_member
    return _check_member_deleted(env["warden"].authenticate!(scope: :member), admin_member?)
  end

  # Return the currently-authenticated user,
  # or respond nil if there is no authenticated user.
  def current_member?
    return _check_member_deleted(env["warden"].user(scope: :member), admin_member?)
  end

  def admin_member
    return _check_member_deleted(env["warden"].authenticate!(scope: :admin), nil)
  end

  def admin_member?
    return _check_member_deleted(env["warden"].authenticate(scope: :admin), nil)
  end

  def authenticate!
    warden = env["warden"]
    user = warden.authenticate!(scope: :member)
    warden.set_user(user, scope: :admin) if user.admin?
    return user
  end

  # Handle denying authentication if the given user cannot auth.
  # That is:
  # - if we have an admin, but they should not be (deleted or missing role), throw unauthed error.
  # - if current user is nil, return nil, since the caller can handle it.
  # - if current user is deleted and there is no admin, throw unauthed error.
  # - if current user is deleted and admin is deleted, throw unauthed error.
  # - otherwise, return current user.
  #
  # The scenarios this covers are:
  # - Normal users cannot auth if deleted.
  # - Admins can sudo deleted users, and current_member still works.
  # - Deleted admins cannot auth or get their sudo'ed user.
  #
  # NOTE: It is safe to throw unauthed errors for deleted users-
  # this does not expose whether a user exists or not,
  # because the only way to call this is via cookies,
  # and cookies are encrypted. So it is impossible to force requests
  # trying to auth/check auth for a user without knowing the secret.
  def _check_member_deleted(user, potential_admin)
    return nil if user.nil?
    if potential_admin && (potential_admin.soft_deleted? || !potential_admin.roles.include?(Suma::Role.admin_role))
      delete_session_cookies
      unauthenticated!
    end
    if user.soft_deleted? && potential_admin.nil?
      delete_session_cookies
      unauthenticated!
    end
    return user
  end

  def delete_session_cookies
    # Nope, cannot do this through Warden easily.
    # And really we should have server-based sessions we can expire,
    # but in the meantime, stomp on the cookie hard.
    options = env[Rack::RACK_SESSION_OPTIONS]
    options[:drop] = true

    # Rack sends a cookie with an empty session, but let's tell the browser to actually delete the cookie.
    cookies.delete(Suma::Service::SESSION_COOKIE, domain: options[:domain], path: options[:path])
    # Set this header to tell the client to delete everything.
    header "Clear-Site-Data", "*"
  end

  def set_member(member)
    warden = env["warden"]
    warden.set_user(member, scope: :member)
    warden.set_user(member, scope: :admin) if member.admin?
  end

  def current_session_id
    return env["rack.session"].id
  end

  def check_role!(member, role_name)
    has_role = member.roles.find { |r| r.name == role_name }
    return if has_role
    role_exists = !Suma::Role.where(name: role_name).empty?
    raise "The role '#{role_name}' does not exist so cannot be checked. You need to create it first." unless role_exists
    merror!(403, "Sorry, this action is unavailable.", code: "role_check")
  end

  def merror!(status, message, code:, more: {}, skip_loc_check: false)
    if !skip_loc_check && Suma::Service.localized_error_codes && !Suma::Service.localized_error_codes.include?(code)
      merror!(500, "Error code is unlocalized: #{code}", code: "unhandled_error")
    end
    header "Content-Type", "application/json"
    body = Suma::Service.error_body(status, message, code:, more:)
    error!(body, status)
  end

  def adminerror!(status, message, code: "admin", more: {})
    merror!(status, message, code:, more:, skip_loc_check: true)
  end

  def unauthenticated!
    merror!(401, "Unauthenticated", code: "unauthenticated")
  end

  def unauthenticated_with_message!(msg)
    env["suma.authfailuremessage"] = msg
    unauthenticated!
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

  # If the search string is only digits (and spaces),
  # return a term used to search the given column.
  # We only search phone if the term is digit-only
  # because otherwise we'd need to remove non-digits from the term,
  # which would mean emails-with-numbers could match phone.
  # That is, '11552' would look for '11552' in phone (and email),
  # so match '11552555555' and 'rob11552@gmail.com'.
  # But we want the term 'rob11552' to match 'rob11552@gmail.com'
  # but NOT match '11552555555'.
  def phone_search_param_to_sql(params, column: :phone, param: :search)
    term = (params[param] || "").strip.gsub(/\s/, "")
    only_digits = term.match?(/^[0-9]+$/)
    return nil unless only_digits
    return search_to_sql(term, column)
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

  def order(dataset, params)
    expr = params[:order_direction] == :asc ? Sequel.asc(params[:order_by]) : Sequel.desc(params[:order_by])
    return dataset.order(expr, Sequel.desc(:id))
  end

  def use_http_expires_caching(expiration)
    return unless Suma::Service.endpoint_caching
    header "Cache-Control", "public"
    header "Expires", expiration.from_now.httpdate
  end

  # Render a liquid template in the 'data' directory.
  # 'vars' are sent into the template when rendering
  # so can be used to render custom vars.
  # If 'styles' is true, render styles.css/liquid into the template.
  # The template should have `{{ styles }}` text somewhere in it.
  def render_liquid(data_rel_path, vars: {}, content_type: "text/html", styles: false)
    if styles
      styles_css = render_liquid_content("assets/styles.css")
      vars["styles"] = render_liquid_content("assets/styles.liquid", vars: {css: styles_css})
    end
    rendered = render_liquid_content(data_rel_path, vars:)
    content_type content_type
    env["api.format"] = :binary
    return rendered
  end

  def render_liquid_content(data_rel_path, vars: {})
    tmpl_file = File.open(Suma::DATA_DIR + data_rel_path)
    liquid_tmpl = Liquid::Template.parse(tmpl_file.read)
    rendered = liquid_tmpl.render!(vars.stringify_keys, registers: {})
    return rendered
  end

  def set_one_relation(model, params, key, id_key: :id)
    return unless params.key?(key)
    value = params.delete(key).delete(id_key)
    model.send("#{key}_#{id_key}=", value)
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

  params :time_range do
    requires :start, as: :begin, type: Time
    requires :end, type: Time
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
    default_order_by = options[:default] || :created_at
    order_by_values = options[:values] || options[:model]&.columns
    raise "Must provide :values or :model for possible orderings" unless order_by_values
    optional :order_by, type: Symbol, values: order_by_values, default: default_order_by
    optional :order_direction, type: Symbol, values: [:asc, :desc], default: :desc
  end

  params :filters do
    optional :filters, type: JSON do
      requires :name, type: String
      optional :operator, type: String, values: ["="], default: "="
      requires :values, type: Array[String], allow_blank: false
    end
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
    blank = options[:allow_blank] || false
    requires :en, type: String, allow_blank: blank
    requires :es, type: String, allow_blank: blank
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
