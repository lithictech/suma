# frozen_string_literal: true

require "suma/service/typewriter"
require "suma/admin_api"

RSpec.describe Suma::Service::Typewriter do
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
       * @typedef {object} Test
       * @description Auto-generated from TestEntity
       * @property {any} x
       * @property {Test} y
       * @property {string} doc - Help text
       * @property {TestEntity} docT - Help text
       * @property {any} n1
       */
    STR
  end

  it "can include extra entities" do
    cls = described_class.extra_admin_classes
    s = described_class.new.build(cls)
    expect(s).to include(<<~STR)
      /**
       * @typedef {object} AdminAction
       * @description Auto-generated from AdminAction
       * @property {string} label
       * @property {string} url
       * @property {Hash} params
       */

      /**
       * @typedef {object} ExternalLink
       * @description Auto-generated from ExternalLink
       * @property {string} url
       * @property {string} label
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
       * @typedef {object} AdminTestActivity
       * @description Auto-generated from AdminTestActivityEntity
       * @property {number} id
       */

      /**
       * @typedef {object} AdminTestActivityEntityCollection
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
       * @typedef {object} AdminTestMember
       * @description Auto-generated from AdminTestMemberEntity
       * @property {AdminTestActivityEntityCollection} activities
       */
    STR
  end
end
