# frozen_string_literal: true

require "suma/service/entity_jsdoc_writer"
require "suma/admin_api"

RSpec.describe Suma::Service::EntityJsdocWriter do
  it "writes entities" do
    Class.new(Grape::Entity) do
      define_singleton_method(:name) { "TestEntity" }
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
    expect(s).to include(<<~STR)
      /**
       * @typedef {Object} Test
       * @description Auto-generated from TestEntity
       * @property {?} x
       * @property {Test} y
       * @property {string} doc - Help text
       * @property {TestEntity} docT - Help text
       * @property {?} n1
       */
    STR
  end

  it "writes admin model entities" do
    activity_entity = Class.new(Suma::AdminAPI::Entities::BaseModelEntity) do
      define_singleton_method(:name) { "AdminTestActivityEntity" }
      model Suma::Member::Activity
      expose :id
    end

    Class.new(Suma::AdminAPI::Entities::BaseModelEntity) do
      define_singleton_method(:name) { "AdminTestMemberEntity" }
      model Suma::Member
      expose_related :activities, with: activity_entity
    end

    cls = described_class.gather_entity_classes(prefix: "AdminTest")
    s = described_class.new.build(cls)
    expect(s).to include(<<~STR)
      /**
       * @typedef {Object} AdminTestActivity
       * @description Auto-generated from AdminTestActivityEntity
       * @property {number} id
       */

      /**
       * @typedef {Object} AdminTestActivityEntityCollection
       * @description Auto-generated from AdminTestActivityEntityCollection
       * @property {string} object
       * @property {number} currentPage
       * @property {number} pageCount
       * @property {number} totalCount
       * @property {boolean} hasMore
       * @property {string} url
       * @property {AdminTestActivity} items
       */

      /**
       * @typedef {Object} AdminTestMember
       * @description Auto-generated from AdminTestMemberEntity
       * @property {AdminTestActivityEntityCollection} activities
       */
    STR
  end
end
