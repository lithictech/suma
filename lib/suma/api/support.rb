# frozen_string_literal: true

require "suma/api"

class Suma::API::Support < Suma::API::V1
  include Suma::API::Entities
  include Suma::Service::Types

  resource :support do
    params do
      requires :previous_phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :current_phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :name, type: String, allow_blank: false
    end
    post :regain_account_access do
      sender_name = params[:name].strip
      lines = [
        "Name: #{sender_name}",
        "Previous Phone: #{Suma::PhoneNumber::US.format(params[:previous_phone])}",
        "Current Phone: #{Suma::PhoneNumber::US.format(params[:current_phone])}",
      ]
      if (prev_member = Suma::Member.with_normalized_phone(params[:previous_phone]))
        lines << "Previous Member: #{prev_member.admin_link}"
      end
      if (current_member = Suma::Member.with_normalized_phone(params[:current_phone]))
        lines << "Current Member: #{current_member.admin_link}"
      end
      Suma::Support::Ticket.create(
        sender_name:,
        subject: "Regain Account Access",
        body: lines.join("\n"),
      )
      status 204
      body ""
    end
  end
end
