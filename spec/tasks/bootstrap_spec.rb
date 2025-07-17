# frozen_string_literal: true

require "suma/tasks/bootstrap"

RSpec.describe Suma::Tasks::Bootstrap, :db do
  before(:all) do
    described_class.new
  end

  it "runs successfully" do
    stub_const("Suma::RACK_ENV", "development")
    req_ip = stub_request(:get, "http://whatismyip.akamai.com/").
      to_return(status: 200, body: "1.1.1.1")
    req_loc = stub_request(:get, "http://ip-api.com/json/1.1.1.1").
      to_return(status: 200, body: {lat: "45", lon: "-120"}.to_json, headers: {"Content-Type" => "application/json"})
    invoke_rake_task("bootstrap")
    expect(Suma::Member.all).to have_length(1)
    expect(Suma::Mobility::Vehicle.all).to have_length(2)
    expect(Suma::Commerce::Offering.all).to have_length(2)
    expect(req_ip).to have_been_made.times(2)
    expect(req_loc).to have_been_made.times(2)
  end

  it "errors if not in development" do
    expect { invoke_rake_task("bootstrap") }.to raise_error(/only run this in development/)
  end

  it "errors if the database is not empty" do
    stub_const("Suma::RACK_ENV", "development")
    Suma::Fixtures.member.create
    expect { invoke_rake_task("bootstrap") }.to raise_error(/only run with a fresh database/)
  end
end
