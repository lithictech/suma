# frozen_string_literal: true

RSpec.describe "system", :integration do
  it "responds to a health check" do
    response = HTTParty.get(url("/api/healthz"))
    expect(response).to party_status(200)
    expect(response).to party_response(eq(o: "k"))
  end

  it "responds to a status check" do
    response = HTTParty.get(url("/api/statusz"))
    expect(response).to party_status(200)
    expect(response).to party_response(include(:version))
  end

  it "routes unknown requests properly" do
    response = HTTParty.get(url("/foo"), follow_redirects: false)
    expect(response).to party_status(302)
    expect(response.headers["Location"]).to eq("/app/foo")
  end

  it "routes app requests properly" do
    response = HTTParty.get(url("/app"))
    expect(response).to party_status(200)
    expect(response.headers["Content-Type"]).to eq("text/html")

    response = HTTParty.get(url("/app/index.html"))
    expect(response).to party_status(200)
    expect(response.headers["Content-Type"]).to eq("text/html")

    response = HTTParty.get(url("/app/favicon.ico"))
    expect(response).to party_status(200)
    expect(response.headers["Content-Type"]).to eq("image/vnd.microsoft.icon")
  end
end
