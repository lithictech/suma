# frozen_string_literal: true

# Helper for classes that define +external_links+.
# Implementers should override +_external_links_self+,
# and if there are dependencies/associations
# which also have external links, return them in +_external_link_deps+.
# Every item should be nil, or a +Link+ instance.
module Suma::ExternalLinks
  class Link < Suma::TypedStruct
    attr_accessor :name, :url
  end

  def external_links(shallow: false)
    d = []
    self._external_links_self.each do |o|
      o.respond_to?(:external_links) ? d.concat(o.external_links) : d.push(o)
    end
    unless shallow
      self._external_link_deps.each do |dep|
        dep && d.concat(dep.external_links(shallow: true))
      end
    end
    return d.filter { |o| o }.uniq(&:url)
  end

  def _external_link(name, url) = Link.new(name:, url:)

  # Return links pointing to data on the object itself
  # like a Lob check or ACH transaction.
  # @return [Array<Link>]
  def _external_links_self = []

  # Return links pointing to data the object depends on,
  # like a Stripe card or Plaid bank account.
  # @return [Array<Link>]
  def _external_link_deps = []
end
