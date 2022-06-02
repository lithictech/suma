# frozen_string_literal: true

# Helper for classes that define external_links.
# Implementers should override external_links_self,
# and if there are dependencies/associations
# which also have external links, return them in _external_link_deps.
# Every item should be nil, or of the form {name:, url:}
module Suma::ExternalLinks
  def external_links(shallow: false)
    d = self._external_links_self
    unless shallow
      self._external_link_deps.each do |dep|
        dep && d.concat(dep.external_links(shallow: true))
      end
    end
    return d.filter { |o| o }.uniq { |h| h[:url] }
  end

  def _external_link(name, url)
    return {name:, url:}
  end

  # Return links pointing to data on the object itself
  # like a Lob check or ACH transaction.
  def _external_links_self
    return []
  end

  # Return links pointing to data the object depends on,
  # like a Stripe card or Plaid bank account.
  def _external_link_deps
    return []
  end
end
