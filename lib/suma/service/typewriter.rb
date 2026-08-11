# frozen_string_literal: true

require "suma/service"
require "grape_entity"

class Suma::Service::Typewriter
  class Formatter
    attr_reader :lines

    def initialize
      @lines = []
    end

    def metadata(classes)
      @lines << "// Auto-generated typedefs from Grape::Entity"
      @lines << "// Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      @lines << "// Entities: #{classes.map(&:name).join(', ')}"
      @lines << ""
    end

    def preamble = nil
    def open_typedef(typename, sourcename) = raise NotImplementedError
    def add_property(js_type, js_name, desc_text) = raise NotImplementedError
    def close_typedef = raise NotImplementedError
    def postamble = nil

    def string = @lines.join("\n")
  end

  class JSDocFormatter < Formatter
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
  end

  class TypescriptFormatter < Formatter
    def preamble
      self.lines << "declare global {"
    end

    def postamble
      self.lines << "}"
      self.lines << ""
      self.lines << "export {};"
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

  def self.gather_web_entity_classes
    cls = [
      Class.new(Grape::Entity) do
        define_singleton_method(:name) { "Money" }
        expose :cents, documentation: {type: "Integer"}
        expose :currency, documentation: {type: "String"}
      end,
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
    ]
    cls.concat(self.gather_entity_classes(glob: "suma/admin_api/*.rb", prefix: "Suma::AdminAPI::"))
    return cls
  end

  def self.gather_entity_classes(glob: nil, prefix: nil)
    Dir.glob(Suma::SELF_DIR + glob).each { |f| require f } if glob
    classes = ObjectSpace.each_object(Class).select do |klass|
      klass < Grape::Entity &&
        klass.name && # skip anonymous classes
        !klass.name.empty?
    end.sort_by(&:name)
    classes = classes.select { |cls| cls.name.start_with?(prefix) } if prefix
    return classes
  end

  # Convert a grape-entity :using or :type value to a JSDoc type string.
  protected def jsdoc_type(using, documentation)
    # Explicit :using — references another entity
    if using
      entity_class = using.is_a?(Proc) ? using.call : using
      return self.jsdoc_entity_name(entity_class)
    end

    # Documentation hint (e.g. documentation: { type: "String" })
    (type = getname(documentation[:type])) if documentation.is_a?(Hash) && documentation[:type]

    return ANYTYPE unless type

    # Grape uses :type as a class, string, or symbol
    mapped = GRAPE_TO_JSTYPE[type.to_s.to_sym]
    return mapped if mapped

    # If it's a Grape::Entity subclass, reference it by name
    return self.jsdoc_entity_name(type) if type.is_a?(Class) && type < Grape::Entity

    # Fallback: stringify
    type.to_s
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

  NUM_PREFIXES = [
    "count",
    "quantity",
  ].freeze
  NUM_SUFFIXES = [
    "id",
    "cents",
    "count",
    "fraction",
    "lat",
    "lng",
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
  ].freeze
  BOOL_SUFFIXES = [
    "enabled",
  ].freeze

  # Derive a clean JSDoc identifier from an entity class name.
  protected def jsdoc_entity_name(klass)
    name = getname(klass)
    # We don't want namespaces
    name = name.split("::").last
    # Strip trailing "Entity" suffix for brevity, e.g. UserEntity → User
    return name.sub(/_?Entity$/, "")
  end

  protected def getname(x) = x.respond_to?(:name) ? x.name : x.to_s

  # Build JSDoc typedef for a single entity class
  # @param [Formatter] formatter
  # @param [Class] entity_class
  protected def write_typedef(formatter, entity_class)
    type_name = self.jsdoc_entity_name(entity_class)
    source_name = entity_class.name

    formatter.open_typedef(type_name, source_name)
    exposures = entity_class.root_exposures
    exposures.each do |exposure|
      # Each exposure may represent a single field or a nested block.
      # We walk recursively if the exposure responds to `nested_exposures`.
      self.walk_exposure(formatter, exposure)
    end
    formatter.close_typedef
  end

  # Build JSDoc typedef for a single entity class
  # @param [Formatter] formatter
  protected def walk_exposure(formatter, exposure)
    # Nested / merge block
    if exposure.respond_to?(:nested_exposures) && exposure.nested_exposures.any?
      exposure.nested_exposures.each do |nested|
        self.walk_exposure(formatter, nested)
      end
      return
    end

    attr_name = exposure.attribute.to_s
    return if attr_name.nil? || attr_name.empty?

    opts = exposure.send(:options)
    # Gather type hints from the exposure's options
    name_as = opts[:as]
    using = opts[:using]
    doc = opts[:documentation]

    attr_name = name_as || attr_name

    js_type = self.jsdoc_type(using, doc)
    js_type = self.guess_jsdoc_type(attr_name) if js_type == ANYTYPE

    desc_text = doc.is_a?(Hash) ? (doc[:desc] || doc[:description]).to_s : ""

    js_name = attr_name.to_s.camelize(:lower)
    formatter.add_property(js_type, js_name, desc_text)
  end

  def build(entity_classes, formatter: JSDocFormatter.new)
    formatter.metadata(entity_classes)

    formatter.preamble
    entity_classes.each do |klass|
      self.write_typedef(formatter, klass)
    end
    formatter.postamble

    output = formatter.string
    return output
  end
end
