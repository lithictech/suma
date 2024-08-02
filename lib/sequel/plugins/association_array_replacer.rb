# frozen-string-literal: true

module Sequel::Plugins::AssociationArrayReplacer
  def self.configure(model, *associations)
    raise Sequel::Error, "model must have loaded `plugin :association_pks` first" unless
      model.plugins.include?(Sequel::Plugins::AssociationPks)
    associations.each do |name|
      refcls = model.association_reflections[name]
      raise Sequel::Error, "#{name} is not a valid association" unless refcls
      refcls[:delay_pks] = false

      setter_method = "replace_#{name}".to_sym
      # To make this safe in the wild (outside this repo),
      # we need to look at the association_pk method name, rather than re-derive it here.
      pk_setter = "#{name.to_s.singularize}_pks=".to_sym
      refcls[:association_array_replacer_method] = setter_method
      refcls[:association_array_pk_setter_method] = setter_method
      model.define_method setter_method do |array|
        self.replace_association_array(name, array, pk_setter:)
      end
    end
  end

  module InstanceMethods
    def replace_association_array(name, array, pk_setter: nil)
      pk_setter ||= self.class.association_reflections.fetch(name).fetch(:association_array_pk_setter_method)
      self.send(pk_setter, array.map(&:pk))
      self.associations.delete(name)
      return array
    end
  end
end
