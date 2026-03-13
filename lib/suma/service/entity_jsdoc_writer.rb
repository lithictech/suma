# frozen_string_literal: true

require "suma/service"

class Suma::Service::EntityJsdocWriter
  GRAPE_TO_JSDOC = {
    # Primitives
    Integer => "number",
    Float => "number",
    BigDecimal => "number",
    Numeric => "number",
    String => "string",
    Symbol => "string",
    "String" => "string",
    "Integer" => "number",
    "Float" => "number",

    # Booleans (grape-entity uses these symbols/strings)
    :boolean => "boolean",
    "Boolean" => "boolean",
    TrueClass => "boolean",
    FalseClass => "boolean",

    # Date / time
    Date => "string",
    DateTime => "string",
    Time => "string",

    # Collections
    Array => "Array",
    Hash => "Object",
  }.freeze

  def self.gather_entity_classes
    ObjectSpace.each_object(Class).select do |klass|
      klass < Grape::Entity &&
        klass.name && # skip anonymous classes
        !klass.name.empty?
    end.sort_by(&:name)
  end

  # Convert a grape-entity :using or :type value to a JSDoc type string.
  protected def jsdoc_type(type, using, documentation)
    # Explicit :using — references another entity
    if using
      entity_class = using.is_a?(Proc) ? using.call : using
      return self.jsdoc_entity_name(entity_class)
    end

    # Documentation hint (e.g. documentation: { type: "string" })
    return documentation[:type].to_s if documentation.is_a?(Hash) && documentation[:type]

    return "?" unless type

    # Grape uses :type as a class, string, or symbol
    mapped = GRAPE_TO_JSDOC[type]
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

    return "?"
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
    name = klass.respond_to?(:name) ? klass.name : klass.to_s
    # We don't want namespaces
    name = name.split("::").last
    # Strip trailing "Entity" suffix for brevity, e.g. UserEntity → User
    return name.sub(/_?Entity$/, "")
  end

  # Build JSDoc typedef for a single entity class
  protected def typedef_for(entity_class)
    lines = []
    type_name = self.jsdoc_entity_name(entity_class)
    source_name = entity_class.name

    lines << "/**"
    lines << " * @typedef {Object} #{type_name}"
    lines << " * @description Auto-generated from #{source_name}"

    exposures = begin
      entity_class.root_exposures
    rescue StandardError
      []
    end

    exposures.each do |exposure|
      # Each exposure may represent a single field or a nested block.
      # We walk recursively if the exposure responds to `nested_exposures`.
      self.walk_exposure(exposure, lines)
    end

    lines << " */"
    lines
  end

  protected def walk_exposure(exposure, lines)
    # Nested / merge block
    if exposure.respond_to?(:nested_exposures) && exposure.nested_exposures.any?
      exposure.nested_exposures.each do |nested|
        self.walk_exposure(nested, lines)
      end
      return
    end

    attr_name = exposure.attribute.to_s
    return if attr_name.nil? || attr_name.empty?

    opts = exposure.send(:options)
    # Gather type hints from the exposure's options
    name_as = opts[:as]
    using = opts[:using]
    type  = opts[:type]
    doc   = opts[:documentation]

    attr_name = name_as || attr_name

    js_type = self.jsdoc_type(type, using, doc)
    js_type = self.guess_jsdoc_type(attr_name) if js_type == "?"

    desc_text = doc.is_a?(Hash) ? (doc[:desc] || doc[:description]).to_s : ""

    js_name = attr_name.to_s.camelize(:lower)
    prop_tag  = "@property {#{js_type}} #{js_name}"
    prop_tag += " - #{desc_text}" unless desc_text.empty?

    lines << " * #{prop_tag}"
  end

  def build(entity_classes)
    output_lines = []
    output_lines << "// Auto-generated JSDoc typedefs from Grape::Entity"
    output_lines << "// Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    output_lines << "// Entities: #{entity_classes.map(&:name).join(', ')}"
    output_lines << ""
    # language=js
    output_lines << <<~JS
      /**
       * @typedef AdminAction
       * @property {string} label
       * @property {string} url
       * @property {object} params
       */

      /**
       * @typedef ExternalLink
       * @property {string} url
       * @property {string} label
       */
    JS

    entity_classes.each_with_index do |klass, i|
      output_lines.concat(typedef_for(klass))
      output_lines << "" unless i == entity_classes.size - 1
    end

    output = output_lines.join("\n")
    return output
  end
end
