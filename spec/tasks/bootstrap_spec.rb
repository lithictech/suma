# frozen_string_literal: true

require "suma/tasks/bootstrap"

RSpec.describe Suma::Tasks::Bootstrap, :db do
  it "runs successfully" do
    req_ip = stub_request(:get, "http://whatismyip.akamai.com/").
      to_return(status: 200, body: "1.1.1.1")
    req_loc = stub_request(:get, "http://ip-api.com/json/1.1.1.1").
      to_return(status: 200, body: {lat: "45", lon: "-120"}.to_json, headers: {"Content-Type" => "application/json"})
    expect { described_class.new.run_task }.to_not raise_error
    expect(Suma::Member.all).to have_length(1)
    expect(Suma::Mobility::Vehicle.all).to have_length(1)
    expect(Suma::Commerce::Offering.all).to have_length(2)
    expect(req_ip).to have_been_made
    expect(req_loc).to have_been_made
  end
end
