# frozen_string_literal: true

require "suma/async"
require "suma/spec_helpers"

module Suma::SpecHelpers::Async
  def self.included(context)
    context.around(:each) do |example|
      if (mode = example.metadata[:sidekiq])
        Sidekiq::Testing.__set_test_mode(mode) do
          Sidekiq::Queues.clear_all
          example.run
        ensure
          Sidekiq::Queues.clear_all
        end
      else
        example.run
      end
    end
  end
end
