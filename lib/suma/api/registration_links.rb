# frozen_string_literal: true

require "suma/api"

class Suma::API::RegistrationLinks < Suma::API::V1
  include Suma::API::Entities

  resource :registration_links do
    get :capture do
      # This URL only exists to capture suma_regcode and then send the user to the app.
      paramkey = Suma::Organization::RegistrationLink::ONE_TIME_CODE_PARAM
      merror!(400, ":#{paramkey} param is required. Refer to RegistrationLink documentation.", code: "required") unless
        params.key?(paramkey)
      redirect Suma::Organization::RegistrationLink.partner_signup_url
    end

    route_param :opaque_id do
      get do
        link = Suma::Organization::RegistrationLink[opaque_id: params[:opaque_id]]
        forbidden! unless link
        new_url = link.make_code_capture_url
        redirect new_url
      end
    end
  end
end
