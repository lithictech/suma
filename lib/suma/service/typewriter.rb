# frozen_string_literal: true

require "suma/service"
require "suma/enum"
require "grape_entity"

class Suma::Service::Typewriter
  class Error < StandardError; end
  class UntypedError < Error; end

  class Formatter
    attr_reader :lines

    def initialize
      @lines = []
      @aliases = {}
    end

    def metadata(classes, enums)
      @lines << "// Auto-generated typedefs from Grape::Entity"
      @lines << "// Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      @lines << "// Entities: #{classes.map(&:name).join(', ')}" if classes.any?
      @lines << "// Enums: #{enums.map(&:fqn).join(', ')}" if enums.any?
      @lines << ""
    end

    def register_alias(name, definition)
      @aliases[name] = definition
    end

    def preamble = nil
    def add_enumeration(name, values) = raise NotImplementedError
    def add_typealias(name, definition) = raise NotImplementedError
    def open_typedef(typename, sourcename) = raise NotImplementedError
    def add_property(js_type, js_name, desc_text) = raise NotImplementedError
    def close_typedef = raise NotImplementedError

    def postamble
      @aliases.each do |name, definition|
        self.add_typealias(name, definition)
      end
    end

    def string = @lines.join("\n")
  end

  class JSDocFormatter < Formatter
    def add_enumeration(name, values)
      self.lines << "/**"
      self.lines << " * @enum {string}"
      self.lines << " */"
      self.lines << "const #{name} = {"
      values.each { |v| self.lines << "  #{v}: '#{v}'," }
      self.lines << "};"
      self.lines << ""
    end

    def open_typedef(typename, sourcename)
      self.lines << "/**"
      self.lines << " * @typedef {object} #{typename}"
      self.lines << " * @description Auto-generated from #{sourcename}"
    end

    def add_property(js_type, js_name, desc_text)
      prop_tag  = "@property {#{js_type}} #{js_name}"
      prop_tag += " - #{desc_text}" unless desc_text.empty?
      self.lines << " * #{prop_tag}"
    end

    def close_typedef
      self.lines << " */"
      self.lines << ""
    end

    def add_typealias(name, definition)
      self.lines << "/**"
      self.lines << " * @typedef {#{definition}} #{name}"
      self.lines << " */"
      self.lines << ""
    end
  end

  class TypescriptFormatter < Formatter
    def preamble
      self.lines << "declare global {"
    end

    def postamble
      super
      self.lines << "}"
      self.lines << ""
      self.lines << "export {};"
      self.lines << ""
    end

    def add_enumeration(name, values)
      e = values.map { |v| "\"#{v}\"" }.join(" | ")
      self.lines << "  type #{name} = #{e};"
      self.lines << ""
    end

    def open_typedef(typename, sourcename)
      self.lines << "  /** Auto-generated from #{sourcename} */"
      self.lines << "  interface #{typename} {"
    end

    def add_property(js_type, js_name, desc_text)
      self.lines << "    /** #{desc_text} */" unless desc_text.empty?
      self.lines << "    #{js_name}: #{js_type};"
    end

    def close_typedef
      self.lines << "  }"
      self.lines << ""
    end

    def add_typealias(name, definition)
      self.lines << "  type #{name} = #{definition};"
    end
  end

  ANYTYPE = "any"

  GRAPE_TO_JSTYPE = {
    # Primitives
    Integer: "number",
    Float: "number",
    BigDecimal: "number",
    Numeric: "number",
    String: "string",
    Symbol: "string",

    # Booleans (grape-entity uses these symbols/strings)
    boolean: "boolean",
    Boolean: "boolean",
    TrueClass: "boolean",
    FalseClass: "boolean",

    # Date / time
    Date: "string",
    DateTime: "string",
    Time: "string",

    # Collections
    Array: "#{ANYTYPE}[]",
    Hash: ANYTYPE,
    Object: ANYTYPE,
  }.freeze

  def self.global_classes
    return [
      Class.new(Grape::Entity) do
        define_singleton_method(:js_typename) { "UnboundedApiCollection<T>" }
        expose :items, documentation: {type: "T", array: true}
      end,
      Class.new(Grape::Entity) do
        define_singleton_method(:js_typename) { "ApiCollection<T>" }
        expose :object, documentation: {type: String}
        expose :current_page, documentation: {type: Integer}
        expose :page_count, documentation: {type: Integer}
        expose :total_count, documentation: {type: Integer}
        expose :has_more, documentation: {type: "boolean"}
        expose :url, documentation: {type: String}
        expose :items, documentation: {type: "T", array: true}
      end,
    ]
  end

  def self.gather_web_entity_classes
    cls = [
      Class.new(Grape::Entity) do
        define_singleton_method(:name) { "Money" }
        expose :cents, documentation: {type: "Integer"}
        expose :currency, documentation: {type: "String"}
      end,
      *self.global_classes,
    ]
    cls.concat(self.gather_entity_classes(glob: "suma/api/*.rb", prefix: "Suma::API::"))
    return cls
  end

  def self.gather_admin_entity_classes
    cls = [
      Class.new(Grape::Entity) do
        define_singleton_method(:name) { "AdminAction" }
        expose :label, documentation: {type: "String"}
        expose :url, documentation: {type: "String"}
        expose :params, documentation: {type: "Object"}
      end,
      Class.new(Grape::Entity) do
        define_singleton_method(:name) { "ExternalLink" }
        expose :url, documentation: {type: "String"}
        expose :label, documentation: {type: "String"}
      end,
      *self.global_classes,
    ]
    cls.concat(self.gather_entity_classes(glob: "suma/admin_api/*.rb", prefix: "Suma::AdminAPI::"))
    return cls
  end

  def self.gather_entity_classes(glob: nil, prefix: nil)
    Dir.glob(Suma::SELF_DIR + glob).each { |f| require f } if glob
    classes = ObjectSpace.each_object(Class).select do |klass|
      next false unless klass < Grape::Entity
      next false unless klass.name.present? # skip anonymous classes
      next false if klass.respond_to?(:spec_defined?) && klass.spec_defined?
      true
    end.sort_by(&:name)
    classes = classes.select { |cls| cls.name.start_with?(prefix) } if prefix
    return classes
  end

  # @param [Formatter] formatter
  # @param [true,false] strict
  def initialize(formatter=JSDocFormatter.new, strict: false)
    @formatter = formatter
    # Map enum modules to the typename written into the JS.
    @enum_typenames = {}
    @strict = strict
    @strict_errors = []
  end

  # Convert a grape-entity :using or :type value to a JSDoc type string.
  protected def jsdoc_type(using, documentation)
    # Explicit :using — references another entity
    if using
      entity_class = using.is_a?(Proc) ? using.call : using
      return self.jsdoc_entity_name(entity_class)
    end

    # Documentation hint (e.g. documentation: { type: "String" })
    type = documentation[:type]
    return ANYTYPE unless type

    if (typename = self.register_typealiases(type))
      return typename
    end
    return @enum_typenames[type] if @enum_typenames.key?(type)

    # Grape uses :type as a class, string, or symbol. If we get a mapped hit, just use it.
    mapped = GRAPE_TO_JSTYPE[type.to_s.to_sym]
    return mapped if mapped

    # If it's a Grape::Entity subclass, reference it by name
    return self.jsdoc_entity_name(type) if type.is_a?(Class) && type < Grape::Entity
    return type.to_s
  end

  protected def guess_jsdoc_type(attr)
    attr = attr.to_s

    return "number" if NUM_PREFIXES.any? { |prefix| attr.start_with?("#{prefix}_") }
    return "number" if NUM_SUFFIXES.include?(attr) || NUM_SUFFIXES.any? { |a| attr.end_with?("_#{a}") }

    return "string" if STR_PREFIXES.any? { |prefix| attr.start_with?("#{prefix}_") }
    return "string" if STR_SUFFIXES.include?(attr) || STR_SUFFIXES.any? { |a| attr.end_with?("_#{a}") }

    return "boolean" if BOOL_PREFIXES.any? { |prefix| attr.start_with?("#{prefix}_") }
    return "boolean" if BOOL_SUFFIXES.include?(attr) || BOOL_SUFFIXES.any? { |a| attr.start_with?("_#{a}") }

    return "ExternalLink[]" if attr == "external_links"
    return "AdminAction[]" if attr == "admin_actions"

    return ANYTYPE
  end

  protected def register_typealiases(t)
    return nil unless t.respond_to?(:js_typealias)
    typename = self.jsdoc_entity_name(t)
    @formatter.register_alias(typename, t.js_typealias)
    t.js_typeincludes.each { |ti| self.register_typealiases(ti) } if t.respond_to?(:js_typeincludes)
    return typename
  end

  NUM_PREFIXES = [
    "count",
    "quantity",
  ].freeze
  NUM_SUFFIXES = [
    "id",
    "cents",
    "count",
    "fraction",
    "index",
    "lat",
    "lng",
    "length",
    "multiplier",
    "offset",
    "ordinal",
    "quantity",
  ].freeze
  STR_PREFIXES = [
    "formatted",
  ].freeze
  STR_SUFFIXES = [
    "at",
    "begin",
    "code",
    "content",
    "currency",
    "description",
    "email",
    "en",
    "es",
    "end",
    "html",
    "key",
    "label",
    "last4",
    "link",
    "md",
    "mode",
    "phone",
    "name",
    "reason",
    "slug",
    "state",
    "status",
    "str",
    "template",
    "timezone",
    "token",
    "type",
    "url",
  ].freeze
  BOOL_PREFIXES = [
    "can",
    "is",
    "need",
    "needs",
    "has",
    "requires",
    "show",
  ].freeze
  BOOL_SUFFIXES = [
    "enabled",
    "needed",
  ].freeze

  # Derive a clean JSDoc identifier from an entity class name.
  protected def jsdoc_entity_name(klass)
    return klass.js_typename if klass.respond_to?(:js_typename)
    name = getname(klass)
    raise "class must have a name, but name was: #{name.inspect}" unless name.present?
    # We don't want namespaces
    name = name.split("::").last
    # Strip trailing "Entity" suffix for brevity, e.g. UserEntity → User
    return name.sub(/_?Entity$/, "")
  end

  protected def getname(x) = x.respond_to?(:name) ? x.name : x.to_s

  # Build JSDoc typedef for a single entity class
  # @param [Class] entity_class
  protected def write_typedef(entity_class)
    type_name = self.jsdoc_entity_name(entity_class)
    source_name = entity_class.name

    @formatter.open_typedef(type_name, source_name)
    exposures = entity_class.root_exposures
    property_type_and_desc_for_name = {}
    exposures.each do |exposure|
      # Each exposure may represent a single field or a nested block.
      # We walk recursively if the exposure responds to `nested_exposures`.
      self.walk_exposure(property_type_and_desc_for_name, exposure)
    end
    property_type_and_desc_for_name.each do |jsname, (jstype, desc)|
      @strict_errors << "#{type_name}.#{jsname}" if @strict && jstype.start_with?(ANYTYPE)
      @formatter.add_property(jstype, jsname, desc)
    end
    @formatter.close_typedef
  end

  # Build JSDoc typedef for a single entity class
  # @param [Hash] property_type_and_desc_for_name
  protected def walk_exposure(property_type_and_desc_for_name, exposure)
    # Nested / merge block
    if exposure.respond_to?(:nested_exposures) && exposure.nested_exposures.any?
      exposure.nested_exposures.each do |nested|
        self.walk_exposure(property_type_and_desc_for_name, nested)
      end
      return
    end

    attr_name = exposure.attribute.to_s
    return if attr_name.nil? || attr_name.empty?

    opts = exposure.send(:options)
    # Gather type hints from the exposure's options
    name_as = opts[:as]
    using = opts[:using]
    doc = opts[:documentation] || {}
    # If this is originally a predicate method, use a boolean type
    doc[:type] ||= :Boolean if attr_name.end_with?("?")

    attr_name = name_as || attr_name

    js_type = self.jsdoc_type(using, doc)
    js_type = self.guess_jsdoc_type(attr_name) if js_type == ANYTYPE

    js_type = "#{js_type}[]" if doc[:array]
    js_type = "#{js_type} | null" if doc[:optional]
    desc_text = (doc[:desc] || doc[:description] || "").to_s

    js_name = attr_name.to_s.camelize(:lower)
    property_type_and_desc_for_name[js_name] = [js_type, desc_text]
  end

  # @param {Array<Suma::Enum::Definition>} enum_registry
  protected def handle_registry(enum_registry)
    enum_registry.each do |definition|
      js_enum_name = definition.fqn.split("::")[1..].join
      @formatter.add_enumeration(js_enum_name, definition.values)
      @enum_typenames[definition.module] = js_enum_name
    end
  end

  # @param {Array<Class>} entity_classes
  # @param {Array<Suma::Enum::Definition>} enum_registry
  def build(entity_classes, enum_registry: [])
    @formatter.metadata(entity_classes, enum_registry)

    @formatter.preamble
    self.handle_registry(enum_registry)
    entity_classes.each do |klass|
      self.write_typedef(klass)
    end
    @formatter.postamble

    raise UntypedError, ("exposures were untyped:\n" + @strict_errors.join("\n")) if @strict_errors.any?

    output = @formatter.string
    return output
  end
end
