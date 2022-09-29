# frozen_string_literal: true

module Suma::AdminLinked
  def admin_link
    begin
      ln = self.rel_admin_link
    rescue NoMethodError
      raise NotImplementedError, "AdminLinked must implement :rel_admin_link"
    end
    return Suma.admin_url + ln
  end
end
