# frozen_string_literal: true

require "suma/lyft/pass"

# rubocop:disable Layout/LineLength
RSpec.describe Suma::Lyft::Pass, :db, reset_configuration: Suma::Lyft do
  let(:now) { Time.now }

  before(:each) do
    Suma::Lyft.pass_authorization = "Basic xyz"
    Suma::Lyft.pass_email = "a@b.c"
    Suma::Lyft.pass_org_id = "1234"
    Suma::Lyft.pass_account_id = "5678"

    @vendor_service_rate = Suma::Fixtures.vendor_service_rate.create
    @vendor_service = Suma::Fixtures.vendor_service.mobility.create(vendor: Suma::Lyft.mobility_vendor)
    @vendor_service_rate.add_service(@vendor_service)
    Suma::Lyft.pass_vendor_service_rate_id = @vendor_service_rate.id

    allow(Kernel).to receive(:sleep)
  end

  let(:instance) { Suma::Lyft::Pass.from_config }

  def insert_valid_credential
    Suma::ExternalCredential.create(
      service: "lyft-pass-access-token",
      expires_at: 5.hours.from_now,
      data: {
        body: {
          token_type: "Bearer",
          expires_in: 86_400,
          user_id: "2050148397576827050",
          scope: "offline privileged.price.upfront profile public rides.active_ride rides.read rides.request scopedurl users.create",
        },
        cookies: {
          sessId: "13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654",
          lyftAccessToken: "V+m2/hgFtHGbqevf8AN0G0w1U7oDeiUDuQrApobOFppRfOkkZoPIZ0NcWkFfABdOKUDABCJmknKEnXay+qfkXegqyGnpH9O1b0vnqCO/rVo6rXqluSCdSzo=",
          stickyLyftBrowserId: "R2nmL1t8b4ZW2Ak9eYMQ2KOe",
        },
      }.to_json,
    )
  end

  describe "find_credential" do
    it "returns an existing, unexpired credential" do
      cred = Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: "",
      )
      expect(instance.find_credential).to be === cred
    end

    it "returns nil if there are no unexpired credentials" do
      expect(instance.find_credential).to be_nil
      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: Time.now,
        data: "{}",
      )
      expect(instance.find_credential).to be_nil
    end
  end

  def stub_requests
    Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
      message_id: "abc",
      from_email: "business@identity.lyftmail.com",
      to_email: "a@b.c",
      subject: "Here's your one-time Lyft Business log-in link",
      timestamp: Time.now,
      data: {HtmlBody: load_fixture_data("lyft_pass/auth_email_html")}.to_json,
    )
    req1 = stub_request(:get, "https://account.lyft.com/auth/email").
      to_return(
        status: 200,
        body: "",
        headers: {
          "set-cookie" => "sessId=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654; Domain=.lyft.com; Path=/; Expires=Thu, 14 Feb 2030 21:24:14 GMT; Secure; SameSite=None",
        },
      )
    req2 = stub_request(:post, "https://api.lyft.com/oauth2/access_token").
      with(
        body: {"grant_type" => "client_credentials"},
        headers: {
          "Authorization" => "Basic xyz",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Cookie" => "sessId=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654",
          "X-Authorization" => "Basic xyz",
        },
      ).to_return(
        status: 200,
        body: {token_type: "Bearer", expires_in: 86_400,
               scope: "privileged.price.upfront public users.create",}.to_json,
        headers: {
          "content-type" => "application/json",
          "set-cookie" => [
            "lyftAccessToken=Q0L4MDlG/jeT0WpRpybi9mDwP/UIq8Xp7RKWCLfYxdQ+WjZbfgvA6IBhPnZ56M2X2ufo67WcOq3AUyTRo4yZXZeTICDndTf0T/be6xhSYi1SHCV27/vMfJw=; Domain=.lyft.com; Expires=Sun, 16-Feb-2025 21:24:14 GMT; Max-Age=86400; Secure; HttpOnly; Path=/; SameSite=None",
            "stickyLyftBrowserId=R2nmL1t8b4ZW2Ak9eYMQ2KOe; Domain=.lyft.com; Expires=Thu, 14-Feb-2030 21:24:14 GMT; Max-Age=157680000; Secure; Path=/; SameSite=None",
          ],
        },
      )
    req3 = stub_request(:post, "https://api.lyft.com/v1/email/login/request").
      with(
        body: {
          email: "a@b.c",
          next_url: "https://www.lyft.com/business/login?login_session_uuid=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654",
          login_session_uuid: "13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654",
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Cookie" => "sessId=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654; lyftAccessToken=Q0L4MDlG/jeT0WpRpybi9mDwP/UIq8Xp7RKWCLfYxdQ+WjZbfgvA6IBhPnZ56M2X2ufo67WcOq3AUyTRo4yZXZeTICDndTf0T/be6xhSYi1SHCV27/vMfJw=; NEXT_LOCALE=en-US; stickyLyftBrowserId=R2nmL1t8b4ZW2Ak9eYMQ2KOe",
        },
      ).
      to_return(
        status: 200,
        body: {authorize_url: "", identity_type: 0, idp_classification: 0}.to_json,
        headers: {"Content-Type" => "application/json"},
      )
    req4 = stub_request(:post, "https://api.lyft.com/oauth2/access_token").
      with(
        body: {
          "email_token" => "AQAAAAGVCxbSwCP_sxRMgx84xOmZH9khVJBTQdE43odtDJe-z_3S3kfWtl0xiTwpDWCMhdsE_V7FVXr0DYX9fFXNoac9c6LsxmA=",
          "grant_type" => "urn:lyft:oauth2:grant_type:email",
          "login_session_uuid" => "13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654",
        },
        headers: {
          "Authorization" => "Basic xyz",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Cookie" => "sessId=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654; lyftAccessToken=Q0L4MDlG/jeT0WpRpybi9mDwP/UIq8Xp7RKWCLfYxdQ+WjZbfgvA6IBhPnZ56M2X2ufo67WcOq3AUyTRo4yZXZeTICDndTf0T/be6xhSYi1SHCV27/vMfJw=; stickyLyftBrowserId=R2nmL1t8b4ZW2Ak9eYMQ2KOe",
          "X-Authorization" => "Basic xyz",
        },
      ).to_return(
        status: 200,
        body: {
          token_type: "Bearer",
          expires_in: 86_400,
          user_id: "2050148397576827050",
          scope: "offline privileged.price.upfront profile public rides.active_ride rides.read rides.request scopedurl users.create",
        }.to_json,
        headers: {
          "content-type" => "application/json",
          "set-cookie" => [
            "lyftAccessToken=V+m2/hgFtHGbqevf8AN0G0w1U7oDeiUDuQrApobOFppRfOkkZoPIZ0NcWkFfABdOKUDABCJmknKEnXay+qfkXegqyGnpH9O1b0vnqCO/rVo6rXqluSCdSzo=; Domain=.lyft.com; Expires=Sun, 16-Feb-2025 21:30:44 GMT; Max-Age=86400; Secure; HttpOnly; Path=/; SameSite=None",
            "stickyLyftBrowserId=wpTRms579XOpA60fYJzMbOqa; Domain=.lyft.com; Expires=Thu, 14-Feb-2030 21:30:44 GMT; Max-Age=157680000; Secure; Path=/; SameSite=None",
            "ephemeralLyftBrowserId=wpTRms579XOpA60fYJzMbOqaF86Oxz1bNUe8bx6zu90AMDJ9; Domain=api.lyft.com; Expires=Thu, 14-Feb-2030 21:30:44 GMT; Max-Age=157680000; Secure; HttpOnly; Path=/oauth2/access_token; SameSite=None",
          ],
        },
      )
    return [req1, req2, req3, req4]
  end

  describe "authenticate" do
    it "runs through the auth flow" do
      reqs = stub_requests
      instance.authenticate
      expect(instance.credential).to be_a(Suma::ExternalCredential)
      expect(reqs).to all(have_been_made)
    end

    it "uses an existing valid credential" do
      cred = Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: "",
      )
      instance.authenticate
      expect(instance.credential).to be === cred
    end
  end

  describe "authenticate!" do
    it "replaces an existing valid credential" do
      reqs = stub_requests
      cred = Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: "",
      )
      instance.authenticate!
      expect(cred.refresh).to have_attributes(data: include('"lyftAccessToken":"V+m2/hgFtHGbqevf8AN0G0w1U7oDeiUDuQrApobOFppRfOkkZoPIZ0NcWkFfABdOKUDABCJmknKEnXay+qfkXegqyGnpH9O1b0vnqCO/rVo6rXqluSCdSzo="'))
      expect(reqs).to all(have_been_made)
    end

    it "errors if the row is never found" do
      stub_requests
      Suma::Webhookdb.postmark_inbound_messages_dataset.delete
      expect { instance.authenticate! }.to raise_error(/lyft never sent the email/)
    end
  end

  describe "fetch_rides" do
    it "fetches rides" do
      insert_valid_credential
      req = stub_request(:post, "https://www.lyft.com/v1/enterprise-insights/search/transactions?organization_id=1234&start_time=1546300800000").
        with(
          headers: {
            "Content-Type" => "application/json",
            "Cookie" => "sessId=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654; lyftAccessToken=V+m2/hgFtHGbqevf8AN0G0w1U7oDeiUDuQrApobOFppRfOkkZoPIZ0NcWkFfABdOKUDABCJmknKEnXay+qfkXegqyGnpH9O1b0vnqCO/rVo6rXqluSCdSzo=; stickyLyftBrowserId=R2nmL1t8b4ZW2Ak9eYMQ2KOe",
            "Origin" => "https://business.lyft.com",
            "Referer" => "https://business.lyft.com",
          },
        ).
        to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json",
          },
          body: {
            "aggs" => {},
            "next_token" => nil,
            "results" =>
              [{"dropped_off_at_iso" => "2024-10-05T14:50:42-07:00",
                "enterprise_product_type" => "Lyft Pass",
                "picked_up_at_iso" => "2024-10-05T14:40:19-07:00",
                "requested_at_iso" => "2024-10-05T14:40:16-07:00",
                "requested_at_iso[utc_offset]" => "UTC-0700",
                "transactions.amount" => "5.85",
                "transactions.currency" => "USD",
                "transactions.id" => "txnhub:1000000037255551881",
                "transactions.transaction_type" => "Charge",
                "transactions.txn_reporting_timestamp" => "2024-10-05T21:55:55.514000+0000",
                "transportation_id" => "2000855261394541610",
                "transportation_sub_type" => "E-Bike",
                "transportation_type" => "Bikes & Scooters",},
               {"dropped_off_at_iso" => "2024-10-03T16:26:52-07:00",
                "enterprise_product_type" => "Lyft Pass",
                "picked_up_at_iso" => "2024-10-03T16:24:19-07:00",
                "requested_at_iso" => "2024-10-03T16:24:19-07:00",
                "requested_at_iso[utc_offset]" => "UTC-0700",
                "transactions.amount" => "3.41",
                "transactions.currency" => "USD",
                "transactions.id" => "txnhub:1000000037204381752",
                "transactions.transaction_type" => "Charge",
                "transactions.txn_reporting_timestamp" => "2024-10-03T23:28:02.848000+0000",
                "transportation_id" => "2000139905194642852",
                "transportation_sub_type" => "Electric Scooter",
                "transportation_type" => "Bikes & Scooters",},],
            "total_results" => 2,
          }.to_json,
        )

      instance.authenticate
      got = instance.fetch_rides
      expect(req).to have_been_made
      expect(got).to include("results" => have_length(2))
    end

    it "errors if not authed" do
      expect { instance.fetch_rides }.to raise_error(/must call authenticate/)
    end
  end

  describe "fetch_ride" do
    it "fetches the ride with the id" do
      insert_valid_credential
      req = stub_request(:get, "https://www.lyft.com/v1/enterprise-insights/detail/transactions-legacy/txnhub:1000000037204381752").
        with(
          headers: {
            "Cookie" => "sessId=13a81d24-242c-4303-9265-0f98a9cb5e43L1739654654; lyftAccessToken=V+m2/hgFtHGbqevf8AN0G0w1U7oDeiUDuQrApobOFppRfOkkZoPIZ0NcWkFfABdOKUDABCJmknKEnXay+qfkXegqyGnpH9O1b0vnqCO/rVo6rXqluSCdSzo=; stickyLyftBrowserId=R2nmL1t8b4ZW2Ak9eYMQ2KOe",
            "Origin" => "https://business.lyft.com",
            "Referer" => "https://business.lyft.com",
          },
        ).
        to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json",
          },
          body: {
            "created_at_ms" => 1_728_165_355_514,
            "money" => {"amount" => 585, "currency" => "USD", "exponent" => 2},
            "ride" => {
              "distance" => 1.649999976158142,
              "dropoff" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:50:42-07:00", "timestamp_ms" => 1_728_165_042_000},
              "line_items" => [
                {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
                {"money" => {"amount" => 385, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
                {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Parking fee (out of station)"},
                {"money" => {"amount" => -585, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
              ],
              "map_image_url" => nil,
              "pickup" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:40:19-07:00", "timestamp_ms" => 1_728_164_419_000},
              "request" => {"iso_timestamp" => "2024-10-05T14:40:16-07:00", "timestamp_ms" => 1_728_164_416_000},
              "ride_id" => "2000855261394541610",
              "ride_type_description" => "E-Bike",
              "rideable_type" => "ELECTRIC_BIKE",
              "rider" => {"email_address" => "fakeuser@mysuma.org", "full_name" => nil, "phone_number" => nil},
              "was_canceled" => false,
            },
            "txnhub_transaction_id" => "2000859286786636076",
            "user_name" => "",
          }.to_json,
        )

      instance.authenticate
      got = instance.fetch_ride("txnhub:1000000037204381752")
      expect(req).to have_been_made
      expect(got).to include("created_at_ms" => 1_728_165_355_514)
    end
  end

  describe "upsert_ride_as_trip" do
    let(:ride) do
      {
        "created_at_ms" => 1_728_165_355_514,
        "money" => {"amount" => 585, "currency" => "USD", "exponent" => 2},
        "ride" => {
          "distance" => 1.649999976158142,
          "dropoff" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:50:42-07:00", "timestamp_ms" => 1_728_165_042_000},
          "line_items" => [
            {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
            {"money" => {"amount" => 385, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
            {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Parking fee (out of station)"},
            {"money" => {"amount" => -585, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
          ],
          "map_image_url" => nil,
          "pickup" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:40:19-07:00", "timestamp_ms" => 1_728_164_419_000},
          "request" => {"iso_timestamp" => "2024-10-05T14:40:16-07:00", "timestamp_ms" => 1_728_164_416_000},
          "ride_id" => "2000855261394541610",
          "ride_type_description" => "E-Bike",
          "rideable_type" => "ELECTRIC_BIKE",
          "rider" => {"email_address" => "fakeuser@mysuma.org", "full_name" => nil, "phone_number" => nil},
          "was_canceled" => false,
        },
        "txnhub_transaction_id" => "2000859286786636076",
        "user_name" => "",
      }
    end

    it "inserts a trip, charge, and line items for the member" do
      member = Suma::Fixtures.member.with_cash_ledger.create(email: "fakeuser@mysuma.org")
      Suma::Fixtures.vendor_service.mobility.create(vendor: Suma::Lyft.mobility_vendor)
      charge = instance.upsert_ride_as_trip(ride)
      expect(charge).to have_attributes(member:)
      expect(charge.on_platform_line_items).to be_empty
      expect(charge.off_platform_line_items).to contain_exactly(
        have_attributes(amount: cost("$1")),
        have_attributes(amount: cost("$3.85")),
        have_attributes(amount: cost("$1")),
        have_attributes(amount: cost("-$5.85")),
      )
    end

    it "logs and noops if a trip with the external trip/ride id already exists" do
      Suma::Fixtures.member.with_cash_ledger.create(email: "fakeuser@mysuma.org")
      Suma::Fixtures.vendor_service.mobility.create(vendor: Suma::Lyft.mobility_vendor)
      expect(instance.upsert_ride_as_trip(ride)).to be_a(Suma::Charge)
      logs = capture_logs_from(described_class.logger, level: :debug, formatter: :json) do
        expect(instance.upsert_ride_as_trip(ride)).to be_nil
      end
      expect(logs).to include(
        include_json(message: eq("ride_already_exists")),
      )
    end

    it "logs and noops if there is no member for the email" do
      logs = capture_logs_from(described_class.logger, level: :debug, formatter: :json) do
        expect(instance.upsert_ride_as_trip(ride)).to be_nil
      end
      expect(logs).to include(
        include_json(message: eq("no_member_for_rider")),
      )
    end

    it "errors if there is no lyft mobility vendor service category" do
      Suma::Fixtures.member.with_cash_ledger.create(email: "fakeuser@mysuma.org")
      @vendor_service.remove_all_rates
      expect do
        instance.upsert_ride_as_trip(ride)
      end.to raise_error(/No mobility vendor service for Lyft vendor/)
    end
  end
end
# rubocop:enable Layout/LineLength
