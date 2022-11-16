# frozen_string_literal: true

require "suma/i18n"
require "suma/spec_helpers"

module Suma::SpecHelpers::I18n
  def self.included(context)
    context.around(:each) do |example|
      lang = example.metadata[:lang] || example.metadata[:language]
      lang = :en if lang == true
      if lang
        SequelTranslatedText.language(lang) do
          example.run
        rescue SequelTranslatedText::NoContext
          raise SequelTranslatedText::NoContext, "Use :lang or lang: <language> in spec metadata for this spec"
        end
      else
        example.run
      end
    end
    super
  end

  module_function def translated_text(opt)
    params = {}
    if opt.is_a?(String)
      params[:all] = opt
    else
      params.merge!(opt)
    end
    return Suma::TranslatedText.create(params)
  end
end
