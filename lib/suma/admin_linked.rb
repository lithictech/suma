# frozen_string_literal: true

module Suma::AdminLinked
  private def _rel_admin_link
    return self.rel_admin_link
  rescue NoMethodError
    raise NotImplementedError, "#{self.class} must implement :rel_admin_link"
  end

  def admin_link
    return Suma.admin_url + _rel_admin_link
  end

  def rooted_admin_link
    u = URI(Suma.admin_url)
    return u.path + _rel_admin_link
  end
end
