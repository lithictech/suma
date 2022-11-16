# frozen_string_literal: true

require "sequel"
require "sequel/model"
require "sequel/sequel_translated_text"

module Sequel::Plugins::TranslatedText
  def self.configure(model, association_name, text_model_class, opts={})
    association_opts = opts.fetch(:association_opts, {})
    model.many_to_one association_name, class: text_model_class, **association_opts
    key = model.association_reflections[association_name].fetch(:key)

    if (rev = opts[:reverse])
      text_model_class.one_to_one rev, key:, class: model, readonly: true
    end

    unless text_model_class.instance_methods.include?(:string)
      text_model_class.define_method(:string) do
        txt = self.send(SequelTranslatedText.language!)
        (txt = self.send(SequelTranslatedText.default_language)) if
          SequelTranslatedText.default_language && txt.blank?
        txt || ""
      end

      text_model_class.define_method(:string=) do |val|
        self.send("#{SequelTranslatedText.language!}=", val)
      end
    end

    model.instance_eval do
      define_method(:before_create) do
        if self[key].nil?
          self.send("#{association_name}=", text_model_class.create)
        else
          self.send(association_name).save_changes
        end
        super()
      end

      define_method(:before_update) do
        self.send(association_name).save_changes if self[key]
        super()
      end

      define_method(:save_changes) do |*args|
        self.send(association_name).save_changes if self[key]
        super(*args)
      end

      define_method("#{association_name}_string") do
        return self.send(association_name)&.string || ""
      end

      define_method("#{association_name}_string=") do |val|
        txt = self.send(association_name)
        if txt.nil?
          txt = text_model_class.create
          self.send("#{association_name}=", txt)
        end
        txt.string = val
      end
    end
  end

  module InstanceMethods
  end

  module ClassMethods
  end

  module DatasetMethods
    def translation_join(association, translation_columns)
      selects = [
        Sequel[self.first_source_alias][Sequel.lit("*")],
      ]
      selects.concat(translation_columns.map { |c| Sequel[association][c].as("#{association}_#{c}") })
      ds = self.association_join(association).select(*selects)
      return self.from(ds)
    end
  end
end
