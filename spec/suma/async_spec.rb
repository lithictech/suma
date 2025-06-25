# frozen_string_literal: true

require "suma/async/autoscaler"

RSpec.describe Suma::Async do
  describe "Autoscaler" do
    it "starts an autoscaler" do
      Suma::Async::Autoscaler.start
      Suma::Async::Autoscaler.instance.stop
    end
  end

  describe "JobLogger" do
    it "returns configured slow seconds" do
      expect(Suma::Async::JobLogger.new(Sidekiq::Config.new).method(:slow_job_seconds).call).to eq(1)
    end
  end
end
