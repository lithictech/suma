# frozen_string_literal: true

require "suma/service/entity_jsdoc_writer"

RSpec.describe Suma::Service::EntityJsdocWriter do
  it "writes entities" do
    Class.new(Grape::Entity) do
      def self.name = "TestEntity"
      expose :x
      expose :y, using: self
      expose :doc, documentation: {type: "String", desc: "Help text"}
      expose :doc_t, documentation: {type: self, desc: "Help text"}
      expose :nested do
        expose :n1
      end
    end
    cls = described_class.gather_entity_classes(prefix: "TestEntity")
    s = described_class.new.build(cls)
    expect(s).to include("@typedef {Object} Test")
  end
end
