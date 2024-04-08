# frozen_string_literal: true

require "amigo"
require "suma/postgres"

# A collection of utilities that can be added to model superclasses.
module Suma::Postgres::ModelPubsub
  def self.extended(model_class)
    super
    model_class.plugin(:dirty)
    model_class.extend(ClassMethods)
    model_class.include(InstanceMethods)
  end

  module ClassMethods
    def event_prefix
      prefix = self.name or return # No events for anonymous classes
      return prefix.gsub("::", ".").downcase
    end

    # Given a +topic+ string, like 'domain.model.created',
    # find the model class for it.
    # Note that multiple models may share a prefix,
    # like `domain.model` and `domain.model.submodel`.
    # Always return the most 'nested' model, so that a topic of
    # 'domain.model.submodel.created' returns `Domain::Model::Submodel`.
    def model_for_event_topic(topic); end
  end

  module InstanceMethods
    # Return the string used as a topic for events sent from the receiving object.
    def event_prefix = self.class.event_prefix

    # Publish an event from the receiving object of the specified +type+ and with the given +payload+.
    # This does *not* wait for the transaction to complete, so subscribers may not be able to observe
    # any model changes in the database. You probably want to use published_deferred.
    def publish_immediate(type, *payload)
      prefix = self.event_prefix or return
      Amigo.publish(prefix + "." + type.to_s, *payload)
    end

    # Publish an event in the current db's/transaction's +after_commit+ hook.
    def publish_deferred(type, *payload)
      Suma::Postgres.defer_after_commit(self.db) do
        self.publish_immediate(type, *payload)
      end
    end

    # Sequel hook -- send an asynchronous event after the model is saved.
    def after_create
      super
      self.publish_deferred("created", self.id, self._clean_payload(self.values))
    end

    # Sequel hook -- send an asynchronous event after the save is committed.
    def after_update
      super
      self.publish_deferred("updated", self.id, self._clean_payload(self.previous_changes, values_are_pairs: true))
    end

    # Sequel hook -- send an event after a transaction that destroys the object is committed.
    def after_destroy
      super
      self.publish_deferred("destroyed", self.id, self._clean_payload(self.values))
    end

    def _clean_payload(h, values_are_pairs: false)
      result = h.dup
      h.each_pair do |k, v|
        call_unquoted_lit = (v.respond_to?(:to_ary) ? v : [v]).any? { |o| o.respond_to?(:unquoted_literal) }
        next unless call_unquoted_lit
        ds = self.class.dataset
        # unquoted_literal is not an interface method and its arity is not consistent,
        # so we may need to make this more complex in the future.
        # Note, I have seen nils here in the array along with ranges,
        # but was not able to repro it in a test, so we use null coalesce to protect and keep
        # the json value as nil.
        result[k] = values_are_pairs ? v.map { |o| o&.unquoted_literal(ds) } : v&.unquoted_literal(ds)
      end
      return result.as_json
    end
  end
end
