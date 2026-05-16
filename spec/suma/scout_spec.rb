# frozen_string_literal: true

require "grape"
require "suma/scout"

RSpec.describe Suma::Scout, reset_configuration: Suma::Scout do
  it "knows if it is monitoring" do
    described_class.key = "x"
    described_class.monitor = true
    expect(described_class.monitoring?).to be(true)

    described_class.key = "x"
    described_class.monitor = false
    expect(described_class.monitoring?).to be(false)

    described_class.key = ""
    described_class.monitor = true
    expect(described_class.monitoring?).to be(false)
  end

  describe "middleware" do
    let(:app) { ->(_e) { [200, {}, "yup"] } }
    let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo/123/"} }

    it "noops if not monitoring" do
      described_class.install?
      mw = described_class::RackMiddleware.new(app)
      # If scout hasn't been imported, this won't be defined, so we can't mock it.
      expect(ScoutApm::Rack).to_not receive(:transaction) if defined?(ScoutApm)
      expect(mw.call(env)).to eq([200, {}, "yup"])
    end

    describe "when scout is monitoring" do
      before(:each) do
        described_class.key = "x"
        described_class.monitor = true
        described_class.install?
      end

      it "creates a Scout transaction" do
        mw = described_class::RackMiddleware.new(app)
        expect(ScoutApm::Rack).to receive(:transaction).with("GET /foo/123", env).and_call_original
        expect(mw.call(env)).to eq([200, {}, "yup"])
      end

      describe "with a Grape endpoint" do
        include Rack::Test::Methods

        let(:app) do
          api = Class.new(Grape::API) do
            get "/foo/:id" do
              present({id: params[:id]})
            end
          end

          Rack::Builder.new do
            use Suma::Scout::RackMiddleware
            run api
          end
        end

        it "renames the transaction with Grape fields if available" do
          expect(ScoutApm::Rack).to receive(:transaction).with("GET /foo/123", anything).and_call_original
          expect(ScoutApm::Transaction).to receive(:rename).with("GET /foo/:id")
          get "/foo/123/"
          expect(last_response).to have_status(200)
        end
      end
    end
  end
end
