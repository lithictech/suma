# frozen_string_literal: true

require "suma/message/template"

module Suma::Messages::Testers
  class Base < Suma::Message::Template
    def template_folder
      return "specs"
    end

    def layout
      return nil
    end
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
    def template_name
      return "with_field"
    end
  end

  class WithInclude < Base
    def liquid_drops
      return super.merge(field: 3)
    end
  end

  class WithPartial < Base
  end

  class WithLayout < Base
    def template_name
      return "basic"
    end

    def layout
      return "standard"
    end
  end

  class EatArgs < Base
    def initialize(*)
      super()
    end

    def template_name
      return "basic"
    end
  end

  class Localized < Base
    def localized? = true
  end
end
