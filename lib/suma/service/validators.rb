# frozen_string_literal: true

require "grape/validations/validators/base"

module Suma::Service::Validators
end

class Suma::Service::Validators::UsPhone < Grape::Validations::Validators::Base
  def validate_param!(attr_name, params)
    val = params[attr_name]
    return if val.blank? && @allow_blank
    return if Suma::PhoneNumber::US.valid?(val)
    raise Grape::Exceptions::Validation.new(
      params: [@scope.full_name(attr_name)],
      message: "must be a 10-digit US phone",
    )
  end
end
