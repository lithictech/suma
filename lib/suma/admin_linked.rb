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

  # Return the appropriate admin label for a resource.
  # Callers can implement their own admin_label, or this method will make a best-guess.
  def admin_label
    return self.label if self.respond_to?(:label)
    if self.respond_to?(:name) && (name = self.name)
      return name if name.is_a?(String)
      return name.en if name.respond_to?(:en)
    end
    return "#{self.class.name.split('::').last} #{self.pk}"
  end

  # Return a label useful for search (by default, the admin label with the id as a prefix).
  def search_label
    lbl = self.admin_label
    has_pk = /\b#{self.pk}\b/.match?(lbl)
    return has_pk ? lbl : "(#{self.pk}) #{lbl}"
  end
end
