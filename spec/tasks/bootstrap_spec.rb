# frozen_string_literal: true

require "suma/tasks/bootstrap"

RSpec.describe Suma::Tasks::Bootstrap, :db do
  before(:each) do
    # We don't want to mock http calls here, not worth it.
    Suma::Lime.reset_configuration
  end

  it "runs successfully" do
    expect { described_class.new.run_task }.to_not raise_error
    # Should be idempotent, able to be called multiple times
    expect { described_class.new.run_task }.to_not raise_error
  end
end
