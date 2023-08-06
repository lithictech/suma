# frozen_string_literal: true

require "suma/tasks/bootstrap"

RSpec.describe Suma::Tasks::Bootstrap,
               :db,
               # We don't want to mock http calls here, not worth it.
               reset_configuration: [Suma::Lyft, Suma::Lime] do
  it "runs successfully" do
    expect { described_class.new.run_task }.to_not raise_error
    # Should be idempotent, able to be called multiple times
    expect { described_class.new.run_task }.to_not raise_error
  end
end
