class Suma::Service::EntityJsdocWriter

  GRAPE_TO_JSDOC = {
    # Primitives
    Integer   => "number",
    Float     => "number",
    BigDecimal => "number",
    Numeric   => "number",
    String    => "string",
    Symbol    => "string",
    "String"  => "string",
    "Integer" => "number",
    "Float"   => "number",

    # Booleans (grape-entity uses these symbols/strings)
    :boolean  => "boolean",
    "Boolean" => "boolean",
    TrueClass  => "boolean",
    FalseClass => "boolean",

    # Date / time
    Date      => "string",
    DateTime  => "string",
    Time      => "string",

    # Collections
    Array     => "Array",
    Hash      => "Object",
  }.freeze

  def self.gather_entity_classes
    ObjectSpace.each_object(Class).select do |klass|
      klass < Grape::Entity &&
        klass.name &&              # skip anonymous classes
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
    if documentation.is_a?(Hash) && documentation[:type]
      return documentation[:type].to_s
    end

    return "?" unless type

    # Grape uses :type as a class, string, or symbol
    mapped = GRAPE_TO_JSDOC[type]
    return mapped if mapped

    # If it's a Grape::Entity subclass, reference it by name
    if type.is_a?(Class) && type < Grape::Entity
      return self.jsdoc_entity_name(type)
    end

    # Fallback: stringify
    type.to_s
  end

  # Derive a clean JSDoc identifier from an entity class name.
  protected def jsdoc_entity_name(klass)
    name = klass.respond_to?(:name) ? klass.name : klass.to_s
    # Strip trailing "Entity" suffix for brevity, e.g. UserEntity → User
    name.gsub("::", "_").sub(/_?Entity$/, "")
  end

  # Build JSDoc typedef for a single entity class
  protected def typedef_for(entity_class)
    lines = []
    type_name = self.jsdoc_entity_name(entity_class)
    source_name = entity_class.name

    lines << "/**"
    lines << " * @typedef {Object} #{type_name}"
    lines << " * @description Auto-generated from #{source_name}"

    exposures = entity_class.root_exposures rescue []

    exposures.each do |exposure|
      # Each exposure may represent a single field or a nested block.
      # We walk recursively if the exposure responds to `nested_exposures`.
      self.walk_exposure(exposure, "", lines)
    end

    lines << " */"
    lines
  end

  protected def walk_exposure(exposure, prefix, lines)
    # Nested / merge block
    if exposure.respond_to?(:nested_exposures) && exposure.nested_exposures.any?
      exposure.nested_exposures.each do |nested|
        self.walk_exposure(nested, prefix, lines)
      end
      return
    end

    attr_name = exposure.attribute.to_s rescue nil
    return if attr_name.nil? || attr_name.empty?

    full_name = prefix.empty? ? attr_name : "#{prefix}.#{attr_name}"

    # Gather type hints from the exposure's options
    opts = exposure.options rescue {}
    using = opts[:using]
    type  = opts[:type]
    doc   = opts[:documentation]
    is_array = opts[:is_array]

    js_type = self.jsdoc_type(type, using, doc)

    # Wrap in Array<...> when :is_array or :using with an array type
    if is_array || (using && opts[:is_array] != false && guess_array?(exposure))
      js_type = "Array<#{js_type}>"
    end

    optional = !opts[:required]
    desc_text = doc.is_a?(Hash) ? (doc[:desc] || doc[:description]).to_s : ""

    prop_tag  = optional ? "@property {#{js_type}} [#{full_name}]" : "@property {#{js_type}} #{full_name}"
    prop_tag += " - #{desc_text}" unless desc_text.empty?

    lines << " * #{prop_tag}"

    # If using another entity AND we have sub-exposures, recurse with dotted prefix
    if using
      sub_class = using.is_a?(Proc) ? using.call : using
      if sub_class < Grape::Entity
        (sub_class.root_exposures rescue []).each do |nested|
          self.walk_exposure(nested, full_name, lines)
        end
      end
    end
  end

  # Heuristic: if the exposure was declared with `expose :items, using: Foo`
  # and the attribute name looks plural, guess it's an array.
  def guess_array?(_exposure)
    false # conservative default; :is_array option is the authoritative source
  end

  def build(entity_classes)
    output_lines = []
    output_lines << "// Auto-generated JSDoc typedefs from Grape::Entity"
    output_lines << "// Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    output_lines << "// Entities: #{entity_classes.map(&:name).join(', ')}"
    output_lines << ""

    entity_classes.each_with_index do |klass, i|
      output_lines.concat(typedef_for(klass))
      output_lines << "" unless i == entity_classes.size - 1
    end

    output = output_lines.join("\n")
    return output
  end
end
