# frozen_string_literal: true

module Suma::Lyft
  include Appydays::Configurable

  configurable(:lyft) do
    setting :pass_authorization, ""
    setting :pass_email, ""
    setting :pass_org_id, ""
  end
end
