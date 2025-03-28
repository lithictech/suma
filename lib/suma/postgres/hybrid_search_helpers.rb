# frozen_string_literal: true

module Suma::Postgres::HybridSearchHelpers
  def hybrid_search_text
    lines = [
      "I am a #{self.class.name.gsub('::', ' ')}.",
    ]
    if (fields = self.hybrid_search_fields).present?
      lines << "I have the following fields:"
      fields.each do |field|
        if field.is_a?(Symbol)
          k = field.to_s.humanize
          v = self.send(field)
        else
          k, v = field
        end
        v = v.httpdate if v.respond_to?(:httpdate)
        v = v.format if v.is_a?(Money)
        v = v.en if v.is_a?(Suma::TranslatedText)
        v = v.name if v.respond_to?(:name)
        lines << "#{k}: #{v}"
      end
    end
    if (facts = self.hybrid_search_facts).present?
      lines << "The following facts are known about me:"
      lines.concat(facts)
    end
    return lines.select(&:present?).join("\n")
  end

  def hybrid_search_fields = []
  def hybrid_search_facts = []
end
