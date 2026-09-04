# frozen_string_literal: true

require "suma/service/typewriter"
require "suma/admin_api"

RSpec.describe Suma::Service::Typewriter do
  it "writes entities" do
    Class.new(Suma::Service::Entities::Base) do
      define_singleton_method(:name) { "TestEntity" }
      expose :x
      expose :y, using: self
      expose_array :z, self
      expose? :n, documentation: {type: Integer}
      expose :doc, documentation: {type: "String", desc: "Help text"}
      expose :doc_t, documentation: {type: self, desc: "Help text"}
      expose :predicate?, as: :predicate
      expose :nested do
        expose :n1
      end
    end
    cls = described_class.gather_entity_classes(prefix: "TestEntity")
    jsdoc = described_class.new.build(cls)
    expect(jsdoc).to include(<<~STR)
      /**
       * @typedef {object} Test
       * @description Auto-generated from TestEntity
       * @property {any} x
       * @property {Test} y
       * @property {Test[]} z
       * @property {number | null} n
       * @property {string} doc - Help text
       * @property {Test} docT - Help text
       * @property {boolean} predicate
       * @property {any} n1
       */
    STR

    typescript = described_class.new(described_class::TypescriptFormatter.new).build(cls)
    expect(typescript).to include(<<~STR)
      declare global {
        /** Auto-generated from TestEntity */
        interface Test {
          x: any;
          y: Test;
          z: Test[];
          n: number | null;
          /** Help text */
          doc: string;
          /** Help text */
          docT: Test;
          predicate: boolean;
          n1: any;
        }

      }
    STR
  end

  it "uses the jsdoc_type methods on the type class" do
    t1 = Class.new do
      define_singleton_method(:name) { "AliasedType1" }
      define_singleton_method(:js_typealias) { "number[]" }
    end

    t2 = Class.new do
      define_singleton_method(:name) { "AliasedType2" }
      define_singleton_method(:js_typealias) { "AliasedType1[]" }
      define_singleton_method(:js_typeincludes) { [t1] }
    end

    t3 = Class.new do
      define_singleton_method(:name) { "AliasedType3" }
      define_singleton_method(:js_typealias) { "AliasedType2[]" }
      define_singleton_method(:js_typeincludes) { [t2] }
    end

    t4 = Class.new(Suma::Service::Entities::Base) do
      define_singleton_method(:name) { "AliasedType4" }
      define_singleton_method(:js_typename) { "AliasedType4<T>" }
      expose :f, documentation: {type: "T"}
      expose :farr, documentation: {type: "T[]"}
      expose :farr2, documentation: {type: "T", array: true}
    end

    cls = Class.new(Suma::Service::Entities::Base) do
      define_singleton_method(:name) { "AliasedTypeTestEntity" }
      expose :jt, documentation: {type: t3}
    end
    jsdoc = described_class.new.build([cls])
    expect(jsdoc).to include(<<~STR)
      /**
       * @typedef {object} AliasedTypeTest
       * @description Auto-generated from AliasedTypeTestEntity
       * @property {AliasedType3} jt
       */

      /**
       * @typedef {AliasedType2[]} AliasedType3
       */

      /**
       * @typedef {AliasedType1[]} AliasedType2
       */

      /**
       * @typedef {number[]} AliasedType1
       */
    STR

    tsdoc = described_class.new(described_class::TypescriptFormatter.new).build([cls])
    expect(tsdoc).to include(<<~STR)
      declare global {
        /** Auto-generated from AliasedTypeTestEntity */
        interface AliasedTypeTest {
          jt: AliasedType3;
        }

        type AliasedType3 = AliasedType2[];
        type AliasedType2 = AliasedType1[];
        type AliasedType1 = number[];
      }
    STR
  end

  it "uses the jsdoc_typename method if defined" do
    generic = Class.new(Suma::Service::Entities::Base) do
      define_singleton_method(:name) { "Generic" }
      define_singleton_method(:js_typename) { "Generic<T>" }
      expose :f, documentation: {type: "T"}
      expose :farr, documentation: {type: "T[]"}
      expose :farr2, documentation: {type: "T", array: true}
    end

    jsdoc = described_class.new.build([generic])
    expect(jsdoc).to include(<<~STR)
      /**
       * @typedef {object} Generic<T>
       * @description Auto-generated from Generic
       * @property {T} f
       * @property {T[]} farr
       * @property {T[]} farr2
       */
    STR

    tsdoc = described_class.new(described_class::TypescriptFormatter.new).build([generic])
    expect(tsdoc).to include(<<~STR)
      declare global {
        /** Auto-generated from Generic */
        interface Generic<T> {
          f: T;
          farr: T[];
          farr2: T[];
        }
    STR
  end

  it "can write enums" do
    registry = []
    host = Module.new do
      define_singleton_method(:name) { "Suma::Hello" }
    end
    enum = Suma::Enum.define(host, :TypewriterEnum, [:a, :b], registry:)
    cls = Class.new(Suma::Service::Entities::Base) do
      define_singleton_method(:name) { "HasEnum" }
      expose :e, documentation: {type: enum}
    end

    jsdoc = described_class.new.build([cls], enum_registry: registry)
    expect(jsdoc).to include(<<~STR)
      // Enums: Suma::Hello::TypewriterEnum

      /**
       * @enum {string}
       */
      const HelloTypewriterEnum = {
        a: 'a',
        b: 'b',
      };

      /**
       * @typedef {object} HasEnum
       * @description Auto-generated from HasEnum
       * @property {HelloTypewriterEnum} e
       */
    STR

    tsdoc = described_class.new(described_class::TypescriptFormatter.new).build([cls], enum_registry: registry)
    expect(tsdoc).to include(<<~STR)
      // Enums: Suma::Hello::TypewriterEnum

      declare global {
        type HelloTypewriterEnum = "a" | "b";

        /** Auto-generated from HasEnum */
        interface HasEnum {
          e: HelloTypewriterEnum;
        }
    STR
  end

  it "can include extra entities" do
    cls = described_class.gather_admin_entity_classes
    s = described_class.new.build(cls)
    expect(s).to include(<<~STR)
      /**
       * @typedef {object} AdminAction
       * @description Auto-generated from AdminAction
       * @property {string} label
       * @property {string} url
       * @property {any} params
       */
    STR
  end

  it "uses the last exposure for an overridden field" do
    base = Class.new(Grape::Entity) do
      define_singleton_method(:name) { "DupeExposureEntityBase" }
      expose :doc, documentation: {type: "String"}
    end
    sub = Class.new(base) do
      define_singleton_method(:name) { "DupeExposureEntitySub" }
      expose :doc, documentation: {type: "Integer"}
    end
    s = described_class.new.build([sub])
    expect(s).to include(<<~STR)
      /**
       * @typedef {object} DupeExposureEntitySub
       * @description Auto-generated from DupeExposureEntitySub
       * @property {number} doc
       */
    STR
  end

  it "can use a strict mode" do
    cls = Class.new(Suma::Service::Entities::Base) do
      define_singleton_method(:name) { "StrictEntity" }
      expose :x
    end
    expect do
      described_class.new(strict: true).build([cls])
    end.to raise_error(described_class::UntypedError, "exposures were untyped:\nStrict.x")
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
