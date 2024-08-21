# frozen_string_literal: true

module Sequel::Plugins::AssociationDeleter
  def self.configure(model, *associations)
    associations.each do |name|
      refcls = model.association_reflections[name]
      raise Sequel::Error, "#{name} is not a valid association" unless refcls
      unless refcls[:type] == :one_to_many
        msg = "association_deleter many only be used for one_to_many but #{name} is a #{refcls[:type]}"
        raise Sequel::Error, msg
      end
      delete_all_method = :"delete_all_#{name}"
      ds_method = refcls.fetch(:dataset_method)
      refcls[:association_deleter_delete_all_method] = delete_all_method
      model.define_method delete_all_method do
        self.delete_association(name, dataset_method: ds_method)
      end
    end
  end

  module InstanceMethods
    def delete_association(name, dataset_method: nil)
      dataset_method ||= self.class.association_reflections.fetch(name).fetch(:dataset_method)
      self.send(dataset_method).delete
      self.associations[name] = []
    end
  end
end
