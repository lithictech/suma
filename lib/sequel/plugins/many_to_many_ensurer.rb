# frozen_string_literal: true

require "sequel"

module Sequel::Plugins::ManyToManyEnsurer
  DEFAULT_OPTIONS = {
    singular: nil,
  }.freeze
  def self.configure(model, association, opts={})
    opts = DEFAULT_OPTIONS.merge(opts)
    singular = opts[:singular] || association.to_s.singularize
    assoc = model.association_reflections.fetch(association)
    assoc_cls = nil
    model.instance_eval do
      define_method(:"ensure_#{singular}") do |arg|
        assoc_cls ||= Kernel.const_get(assoc.fetch(:class_name))
        many = arg.is_a?(assoc_cls) ? arg : assoc_cls.find!(arg)
        raise "No #{assoc_cls} for #{arg}" if model.nil?
        self.send(assoc.fetch(:add_method), many) if
          self.send(assoc.fetch(:dataset_method)).where(assoc_cls.qualified_primary_key_hash(many.pk)).empty?
      end
    end
  end
end
