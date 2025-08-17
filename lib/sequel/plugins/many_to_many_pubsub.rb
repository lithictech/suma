# frozen_string_literal: true

require "sequel"

module Sequel::Plugins::ManyToManyPubsub
  DEFAULT_OPTIONS = {
    singular: nil,
    publish: ->(name, receiver, many) { receiver.publish_deferred(name, receiver.pk, many.pk) },
  }.freeze
  def self.configure(model, association, opts={})
    opts = DEFAULT_OPTIONS.merge(opts)
    singular = opts[:singular] || association.to_s.singularize
    publish = opts[:publish]
    model.many_to_many(
      association,
      after_add: lambda do |receiver, many|
        publish.call("#{singular}.added", receiver, many)
      end,
      after_remove: lambda do |receiver, many|
        publish.call("#{singular}.removed", receiver, many)
      end,
      **opts,
    )
  end
end
