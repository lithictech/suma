# frozen_string_literal: true

module Sequel::Plugins::LargeAssociationWarning
  DEFAULT_CALLBACK = lambda do |m, assoc, array|
    m.logger.warn(
      "large_assocation_loaded",
      model_pk: m.primary_key,
      model_type: m.class.name,
      model_association: assoc,
      model_association_size: array.size,
    )
  end

  DEFAULT_OPTIONS = {
    threshold: 100,
    callback: DEFAULT_CALLBACK,
  }.freeze

  class << self
    attr_reader :warned_associations

    def configure(model, opts=DEFAULT_OPTIONS)
      opts = DEFAULT_OPTIONS.merge(opts)
      model.large_association_warning_threshold = opts[:threshold]
      model.large_association_warning_callback = opts[:callback]
      @warned_associations = Set.new
    end
  end

  module ClassMethods
    attr_accessor :large_association_warning_threshold, :large_association_warning_callback

    def inherited(subclass)
      super
      [:large_association_warning_threshold, :large_association_warning_callback].each do |m|
        subclass.send("#{m}=", self.send(m))
      end
    end
  end

  module InstanceMethods
    def load_associated_objects(opts, dynamic_opts={})
      results = super
      if results.is_a?(Array) && results.size > model.large_association_warning_threshold
        assoc = opts.fetch(:name)
        warn_key = [self.class, assoc]
        unless Sequel::Plugins::LargeAssociationWarning.warned_associations.include?(warn_key)
          Sequel::Plugins::LargeAssociationWarning.warned_associations.add(warn_key)
          model.large_association_warning_callback[self, assoc, results]
        end
      end
      return results
    end
  end
end
