# frozen_string_literal: true

require "suma/message/template"

module Suma::Messages::Testers
  class Base < Suma::Message::Template
    def template_folder = "specs"
    def layout = nil
  end

  class Basic < Base
  end

  class WithField < Base
    def initialize(field)
      @field = field
      super()
    end

    def liquid_drops
      return super.merge(field: @field)
    end
  end

  class Nonextant < Base
  end

  class MissingField < Base
    def template_name = "with_field"
  end

  class WithInclude < Base
    def liquid_drops
      return super.merge(field: 3)
    end
  end

  class WithPartial < Base
  end

  class WithLayout < Base
    def template_name = "basic"
    def layout = return "standard"
  end

  class EatArgs < Base
    def initialize(*)
      super()
    end

    def template_name = "basic"
  end

  class Localized < Base
    def localized? = true
  end

  class Sensitive < Base
    def template_name = "basic"
    def sensitive? = true
  end
end
