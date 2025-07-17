# frozen_string_literal: true

require "suma"

RSpec.describe Suma::Signals do
  before(:each) do
    described_class.reset
  end

  after(:each) do
    described_class.reset
  end

  describe "install" do
    it "installs handlers that call original signal handlers" do
      called = false
      original = proc { called = true }
      termhandler = nil
      expect(Signal).to receive(:trap).with("TERM") do |&block|
        termhandler = block
        original
      end
      described_class.install
      expect(termhandler).to_not be_nil
      expect(Suma::SHUTTING_DOWN).to be_false
      termhandler.call
      expect(called).to be(true)
      expect(Suma::SHUTTING_DOWN).to be_true
    end

    it "handles original signal handlers" do
      termhandler = nil
      expect(Signal).to receive(:trap).with("TERM") do |&block|
        termhandler = block
        "DEFAULT"
      end
      described_class.install
      expect(termhandler).to_not be_nil
      expect(Suma::SHUTTING_DOWN).to be_false
      termhandler.call
      expect(Suma::SHUTTING_DOWN).to be_true
    end
  end

  describe "handle_term" do
    it "sets the shutdown flags" do
      expect(Suma::SHUTTING_DOWN).to be_false
      expect(Suma::SHUTTING_DOWN_EVENT).to_not be_set
      described_class.handle_term
      expect(Suma::SHUTTING_DOWN).to be_true
      expect(Suma::SHUTTING_DOWN_EVENT).to be_set
    end
  end
end
