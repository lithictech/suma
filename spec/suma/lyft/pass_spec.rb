# frozen_string_literal: true

require "suma/spec_helpers/sentry"

require "suma/lyft/pass"

# rubocop:disable Layout/LineLength
RSpec.describe Suma::Lyft::Pass, :db, reset_configuration: Suma::Lyft do
  let(:instance) { Suma::Lyft::Pass.from_config }
  let(:now) { Time.now }

  before(:each) do
    Suma::Lyft.pass_authorization = "Basic xyz"
    Suma::Lyft.pass_email = "a@b.c"
    Suma::Lyft.pass_org_id = "1234"
    allow(Kernel).to receive(:sleep)
  end

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

  it "errors if any configuration is missing" do
    Suma::Lyft.pass_authorization = ""
    expect { Suma::Lyft::Pass.from_config }.to raise_error(/authorization cannot be blank/)
    Suma::Lyft.pass_authorization = "x"

    Suma::Lyft.pass_email = ""
    expect { Suma::Lyft::Pass.from_config }.to raise_error(/email cannot be blank/)
    Suma::Lyft.pass_email = "x"

    Suma::Lyft.pass_org_id = ""
    expect { Suma::Lyft::Pass.from_config }.to raise_error(/org_id cannot be blank/)
    Suma::Lyft.pass_org_id = "x"
  end

  describe "programs" do
    it "returns suma programs with a lyft pass id set" do
      p1 = Suma::Fixtures.program.create
      p2 = Suma::Fixtures.program.create(lyft_pass_program_id: "abc")
      expect(described_class.programs_dataset.all).to have_same_ids_as(p2)
    end

    it "caches program lookups for 30 minutes" do
      Suma.use_globals_cache = true
      p1 = Suma::Fixtures.program.create(lyft_pass_program_id: "abc")
      expect(described_class.programs_cached).to have_same_ids_as(p1)
      p2 = Suma::Fixtures.program.create(lyft_pass_program_id: "abcd")
      expect(described_class.programs_cached).to have_same_ids_as(p1)
      expect(described_class.programs_cached(now: 40.minutes.from_now)).to have_same_ids_as(p1, p2)
    ensure
      Suma.reset_configuration
    end
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
      got = instance.fetch_rides("5678")
      expect(req).to have_been_made
      expect(got).to include("results" => have_length(2))
    end

    it "errors if not authed" do
      expect { instance.fetch_rides("5678") }.to raise_error(/must call authenticate/)
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
              "rider" => {"email_address" => nil, "full_name" => nil, "phone_number" => "+15552223333"},
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

  describe "sync_trips" do
    let(:vendor_service_rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }

    before(:each) do
      import_localized_backend_seeds
    end

    it "fetches and upserts rides" do
      insert_valid_credential
      program_req = stub_request(:post, "https://www.lyft.com/api/rideprograms/ride-program").
        with(body: {ride_program_id: "5678"}.to_json).
        to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {ride_program: {owner: {id: "9999"}}}.to_json,
        )

      rides_req = stub_request(:post, "https://www.lyft.com/v1/enterprise-insights/search/transactions?organization_id=1234&start_time=1546300800000").
        with(
          body: {
            "size" => 50,
            "next_token" => "",
            "aggs" => nil,
            "query" => {
              "bool" => {"must" => [
                {
                  "nested" => {
                    "path" => "transactions",
                    "query" => {
                      "bool" => {
                        "should" => {"terms" => {"transactions.account_id" => ["9999"]}},
                      },
                    },
                  },
                },
              ]},
            },
            "include" => [
              "enterprise_product_type",
              "transportation_id",
              "transportation_type",
              "transportation_sub_type",
              "transportation_mode",
              "transactions.amount",
              "transactions.currency",
              "transactions.id",
              "transactions.transaction_type",
              "transactions.txn_reporting_timestamp",
              "requested_at_iso",
              "requested_at_iso[utc_offset]",
              "canceled_at_iso",
              "picked_up_at_iso",
              "dropped_off_at_iso",
              "user_full_name",
            ],
            "sort" => [{"requested_at_utc" => {"order" => "desc"}}],
          },
        ).
        to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {
            aggs: {},
            next_token: nil,
            results:
              [
                {
                  dropped_off_at_iso: "2024-10-05T14:50:42-07:00",
                  enterprise_product_type: "Lyft Pass",
                  picked_up_at_iso: "2024-10-05T14:40:19-07:00",
                  requested_at_iso: "2024-10-05T14:40:16-07:00",
                  "requested_at_iso[utc_offset]": "UTC-0700",
                  "transactions.amount": "5.85",
                  "transactions.currency": "USD",
                  "transactions.id": "txnhub:1000000037255551881",
                  "transactions.transaction_type": "Charge",
                  "transactions.txn_reporting_timestamp": "2024-10-05T21:55:55.514000+0000",
                  transportation_id: "2000855261394541610",
                  transportation_sub_type: "E-Bike",
                  transportation_type: "Bikes & Scooters",
                },
              ],
            total_results: 1,
          }.to_json,
        )
      ride_req = stub_request(:get, "https://www.lyft.com/v1/enterprise-insights/detail/transactions-legacy/txnhub:1000000037255551881").
        to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {
            "created_at_ms" => 1_728_165_355_514,
            "money" => {"amount" => 100, "currency" => "USD", "exponent" => 2},
            "ride" => {
              "distance" => 1.649999976158142,
              "dropoff" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:50:42-07:00", "timestamp_ms" => 1_728_165_042_000},
              "line_items" => [{"money" => {"amount" => -100, "currency" => "USD", "exponent" => 2}, "title" => "default"}],
              "map_image_url" => nil,
              "pickup" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:40:19-07:00", "timestamp_ms" => 1_728_164_419_000},
              "request" => {"iso_timestamp" => "2024-10-05T14:40:16-07:00", "timestamp_ms" => 1_728_164_416_000},
              "ride_id" => "2000855261394541610",
              "ride_type_description" => "E-Bike",
              "rideable_type" => "ELECTRIC_BIKE",
              "rider" => {"email_address" => nil, "full_name" => nil, "phone_number" => "+15552223333"},
              "was_canceled" => false,
            },
            "txnhub_transaction_id" => "2000859286786636076",
            "user_name" => "",
          }.to_json,
        )
      member = Suma::Fixtures.member.
        onboarding_verified.
        registered_as_stripe_customer.
        with_cash_ledger.
        create(phone: "15552223333")

      instance.authenticate
      instance.sync_trips_from_program(
        Suma::Fixtures.program.with_pricing(vendor_service:, vendor_service_rate:).create(lyft_pass_program_id: "5678"),
      )
      expect(program_req).to have_been_made
      expect(rides_req).to have_been_made
      expect(ride_req).to have_been_made
      expect(Suma::Mobility::Trip.all).to contain_exactly(
        have_attributes(
          external_trip_id: "2000855261394541610",
          member: be === member,
          vendor_service: be === vendor_service,
          vendor_service_rate: be === vendor_service_rate,
        ),
      )
    end

    it "errors if the lyft pass program id is not set" do
      p = Suma::Fixtures.program.create
      Suma::Fixtures.program_pricing.create(program: p)
      expect { instance.sync_trips_from_program(p) }.to raise_error(/ lyft_pass_program_id /)
    end

    it "errors if there is not only one program pricing" do
      p = Suma::Fixtures.program.create(lyft_pass_program_id: "5678")
      expect { instance.sync_trips_from_program(p) }.to raise_error(/have exactly 1 item/)
      Suma::Fixtures.program_pricing.create(program: p)
      Suma::Fixtures.program_pricing.create(program: p)
      expect { instance.sync_trips_from_program(p) }.to raise_error(/have exactly 1 item/)
    end
  end

  describe "upsert_ride_as_trip" do
    include Suma::SpecHelpers::Sentry

    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }
    let(:program) { Suma::Fixtures.program.create }
    let(:phone) { "15552223333" }
    let!(:member) do
      m = Suma::Fixtures.member.
        onboarding_verified.
        registered_as_stripe_customer.
        with_cash_ledger.
        create(phone:)
      Suma::Fixtures.card.member(m).create
      m
    end

    before(:each) do
      import_localized_backend_seeds
    end

    def ride_json(
      transaction_amount_cents: 100,
      line_items: [{"money" => {"amount" => -100, "currency" => "USD", "exponent" => 2}, "title" => "default"}]
    )
      return {
        "created_at_ms" => 1_728_165_355_514,
        "money" => {"amount" => transaction_amount_cents, "currency" => "USD", "exponent" => 2},
        "ride" => {
          "distance" => 1.649999976158142,
          "dropoff" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:50:59-07:00", "timestamp_ms" => 1_728_165_059_000},
          "line_items" => line_items,
          "map_image_url" => nil,
          "pickup" => {"address" => nil, "iso_timestamp" => "2024-10-05T14:40:00-07:00", "timestamp_ms" => 1_728_164_400_000},
          "request" => {"iso_timestamp" => "2024-10-05T14:40:16-07:00", "timestamp_ms" => 1_728_164_416_000},
          "ride_id" => "2000855261394541610",
          "ride_type_description" => "E-Bike",
          "rideable_type" => "ELECTRIC_BIKE",
          "rider" => {"email_address" => nil, "full_name" => nil, "phone_number" => "+#{phone}"},
          "was_canceled" => false,
        },
        "txnhub_transaction_id" => "2000859286786636076",
        "user_name" => "",
      }
    end

    # Lyft Pass should NEVER generate funding transactions (all paid off-platform)
    # or result in ledger balance changes (subsidy is always created).
    def assert_zero_balances
      expect(member.payment_account.originated_funding_transactions).to be_empty
      member.payment_account.ledgers.each do |led|
        expect(led).to have_attributes(balance: be_zero)
      end
      Suma::Payment::Account.lookup_platform_account.ledgers.each do |led|
        expect(led).to have_attributes(balance: be_zero)
      end
    end

    it "upserts a trip fully paid by suma's Lyft Pass" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 585,
        line_items: [
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
          {"money" => {"amount" => 385, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Parking fee (out of station)"},
          {"money" => {"amount" => -585, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
        ],
      )

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip).to have_attributes(
        duration_minutes: 11,
        image: nil,
        began_at: match_time("2024-10-05T14:40:00-07:00"),
      )
      expect(trip.charge).to have_attributes(
        member:,
        undiscounted_subtotal: cost("$5.85"),
        off_platform_amount: cost("$0"),
      )
      expect(trip.charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Additional charges", cost("$1")],
        ["Riding - $0.35/min (11 min)", cost("$3.85")],
        ["Unlock fee", cost("$1")],
      )
      expect(trip.charge.contributing_book_transactions).to contain_exactly(
        have_attributes(
          amount: cost("$5.85"),
          originating_ledger: have_attributes(account: be === member.payment_account),
          receiving_ledger: have_attributes(account: be === Suma::Payment::Account.lookup_platform_account),
        ),
      )
      assert_zero_balances
    end

    it "upserts a trip partially paid by suma's Lyft Pass" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 285,
        line_items: [
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
          {"money" => {"amount" => 385, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Parking fee (out of station)"},
          {"money" => {"amount" => -285, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
        ],
      )

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip.charge).to have_attributes(
        member:,
        undiscounted_subtotal: cost("$5.85"),
        off_platform_amount: cost("$3"),
      )
      expect(trip.charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Additional charges", cost("$1")],
        ["Riding - $0.35/min (11 min)", cost("$3.85")],
        ["Unlock fee", cost("$1")],
      )
      assert_zero_balances
    end

    it "upserts a trip that costs more than what is calculated by suma's rate" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 600,
        line_items: [
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
          {"money" => {"amount" => 385, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Parking fee (out of station)"},
          {"money" => {"amount" => 15, "currency" => "USD", "exponent" => 2}, "title" => "testing charge"},
          {"money" => {"amount" => -600, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
        ],
      )

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip.charge).to have_attributes(
        member:,
        undiscounted_subtotal: cost("$6"),
        off_platform_amount: cost("$0"),
      )
      expect(trip.charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Additional charges", cost("$1.15")],
        ["Riding - $0.35/min (11 min)", cost("$3.85")],
        ["Unlock fee", cost("$1")],
      )
      assert_zero_balances
    end

    it "upserts a trip that costs exactly what is calculated by suma's rate" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 485,
        line_items: [
          {"money" => {"amount" => 100, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
          {"money" => {"amount" => 385, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
          {"money" => {"amount" => -485, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
        ],
      )

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip.charge).to have_attributes(
        member:,
        undiscounted_subtotal: cost("4.85"),
        off_platform_amount: cost("$0"),
      )
      expect(trip.charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Riding - $0.35/min (11 min)", cost("$3.85")],
        ["Unlock fee", cost("$1")],
      )
      assert_zero_balances
    end

    it "upserts a trip and warns in Sentry if the Lyft trip costs less than expected" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 275,
        line_items: [
          # Line items are not what the rate calculates, so warn.
          {"money" => {"amount" => 90, "currency" => "USD", "exponent" => 2}, "title" => "Unlock fee"},
          {"money" => {"amount" => 185, "currency" => "USD", "exponent" => 2}, "title" => "Ebike ride ($0.35 per min for 11 min)"},
          {"money" => {"amount" => -275, "currency" => "USD", "exponent" => 2}, "title" => "Promo applied"},
        ],
      )
      ride_created = Time.at(ride_json.fetch("created_at_ms") / 1000)
      # Create the trigger since otherwise we call Sentry twice.
      Suma::Fixtures.payment_trigger.
        from_platform_category(Suma::Vendor::ServiceCategory.lookup("Mobility")).
        create(active_during: (ride_created - 1.day)..(ride_created + 1.day))
      expect_sentry_capture(type: :message, arg_matcher: eq("Lyft Pass charge total less than expected"))

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip.charge).to have_attributes(
        member:,
        undiscounted_subtotal: cost("4.85"),
        off_platform_amount: cost("$0"),
      )
      expect(trip.charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Lyft discount", cost("-$2.10")],
        ["Riding - $0.35/min (11 min)", cost("$3.85")],
        ["Unlock fee", cost("$1")],
      )
      assert_zero_balances
    end

    it "creates a subsidy from the fallback ledger and warns in Sentry if there are no valid triggers" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 485,
        line_items: [
          {"money" => {"amount" => 485, "currency" => "USD", "exponent" => 2}, "title" => "charge"},
          {"money" => {"amount" => -485, "currency" => "USD", "exponent" => 2}, "title" => "credit"},
        ],
      )
      expect_sentry_capture(type: :message, arg_matcher: eq("Trip had off platform subsidy but no Payment Triggers"))
      instance.upsert_ride_as_trip(ride, pricing)
      assert_zero_balances
      mobility = Suma::Vendor::ServiceCategory.lookup("Mobility")
      child = mobility.children.first
      uncategorized_subsidy_ledger = Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(child)
      platform_mobility_ledger = Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(mobility)
      member_mobility_ledger = member.payment_account.ensure_ledger_with_category(mobility)
      # See docs for explanation.
      expect(Suma::Payment::BookTransaction.all).to contain_exactly(
        have_attributes(
          amount: cost("4.85"),
          originating_ledger: be === platform_mobility_ledger,
          receiving_ledger: be === uncategorized_subsidy_ledger,
        ),
        have_attributes(
          amount: cost("4.85"),
          originating_ledger: be === uncategorized_subsidy_ledger,
          receiving_ledger: be === member_mobility_ledger,
        ),
        have_attributes(
          amount: cost("4.85"),
          originating_ledger: be === member_mobility_ledger,
          receiving_ledger: be === platform_mobility_ledger,
        ),
      )
    end

    it "creates a subsidy from the ledger specified by a valid trigger" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 485,
        line_items: [
          {"money" => {"amount" => 485, "currency" => "USD", "exponent" => 2}, "title" => "charge"},
          {"money" => {"amount" => -485, "currency" => "USD", "exponent" => 2}, "title" => "credit"},
        ],
      )
      category = Suma::Vendor::ServiceCategory.lookup("Totally Different")
      vendor_service.add_category(category)
      ride_created = Time.at(ride_json.fetch("created_at_ms") / 1000)
      trigger = Suma::Fixtures.payment_trigger.
        from_platform_category(category).
        create(active_during: (ride_created - 1.day)..(ride_created + 1.day))

      instance.upsert_ride_as_trip(ride, pricing)

      platform_ledger = trigger.originating_ledger
      member_ledger = member.payment_account.ensure_ledger_with_category(category)
      expect(platform_ledger.combined_book_transactions).to contain_exactly(
        have_attributes(
          amount: cost("4.85"),
          originating_ledger: be === platform_ledger,
          receiving_ledger: be === member_ledger,
        ),
        have_attributes(
          amount: cost("4.85"),
          originating_ledger: be === member_ledger,
          receiving_ledger: be === platform_ledger,
        ),
      )
      assert_zero_balances
    end

    it "never uses a member's cash ledger balance" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 185,
        line_items: [
          {"money" => {"amount" => 485, "currency" => "USD", "exponent" => 2}, "title" => "charge"},
          {"money" => {"amount" => -185, "currency" => "USD", "exponent" => 2}, "title" => "credit"},
        ],
      )
      Suma::Fixtures.book_transaction.to(member.payment_account.cash_ledger!).create(amount: money("$5"))

      instance.upsert_ride_as_trip(ride, pricing)

      expect(member.payment_account.cash_ledger!).to have_attributes(balance: cost("$5"))
    end

    it "ignores duplicate line items" do
      vendor_service_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(35).create
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:, vendor_service_rate:)
      ride = ride_json(
        transaction_amount_cents: 600,
        line_items: [
          {"money" => {"amount" => 500, "currency" => "USD", "exponent" => 2}, "title" => "charge1"},
          {"money" => {"amount" => 500, "currency" => "USD", "exponent" => 2}, "title" => "charge1"},
          {"money" => {"amount" => 500, "currency" => "USD", "exponent" => 2}, "title" => "charge2"},
          {"money" => {"amount" => -600, "currency" => "USD", "exponent" => 2}, "title" => "credit1"},
          {"money" => {"amount" => -600, "currency" => "USD", "exponent" => 2}, "title" => "credit1"},
          {"money" => {"amount" => -600, "currency" => "USD", "exponent" => 2}, "title" => "credit1"},
          {"money" => {"amount" => -100, "currency" => "USD", "exponent" => 2}, "title" => "credit2"},
          {"money" => {"amount" => -100, "currency" => "USD", "exponent" => 2}, "title" => "credit2"},
        ],
      )

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$10"),
        off_platform_amount: cost("$3"),
      )
      expect(trip.charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Additional charges", cost("$5.15")],
        ["Riding - $0.35/min (11 min)", cost("$3.85")],
        ["Unlock fee", cost("$1")],
        ["credit2", cost("-$1")],
      )
      assert_zero_balances
    end

    it "errors if the transaction amount is not present as a line item" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      ride = ride_json(
        transaction_amount_cents: 600,
        line_items: [
          {"money" => {"amount" => 600, "currency" => "USD", "exponent" => 2}, "title" => "charge1"},
          {"money" => {"amount" => -599, "currency" => "USD", "exponent" => 2}, "title" => "credit2"},
        ],
      )
      expect do
        instance.upsert_ride_as_trip(ride, pricing)
      end.to raise_error(Suma::InvariantViolation, /transaction amount not found/)
    end

    it "errors if the suma subsidy is zero" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      ride = ride_json(
        transaction_amount_cents: 0,
        line_items: [
          {"money" => {"amount" => 600, "currency" => "USD", "exponent" => 2}, "title" => "charge1"},
          {"money" => {"amount" => -0, "currency" => "USD", "exponent" => 2}, "title" => "credit2"},
        ],
      )
      expect do
        instance.upsert_ride_as_trip(ride, pricing)
      end.to raise_error(Suma::InvariantViolation, /transaction amount cannot be zero/)
    end

    it "will download and insert a map image if the url is set" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      ride = ride_json
      ride["ride"]["map_image_url"] = "https://example.com/map.png"
      stub_request(:get, "https://example.com/map.png").
        to_return(status: 200, body: Suma::SpecHelpers::PNG_1X1_BYTES, headers: {"Content-Type" => "image/png"})

      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(trip).to have_attributes(
        image: have_attributes(
          uploaded_file: have_attributes(private: true, content_type: "image/png"),
        ),
      )
    end

    it "noops if a trip with the external trip/ride id already exists" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      ride = ride_json
      trip = instance.upsert_ride_as_trip(ride, pricing)
      expect(instance.upsert_ride_as_trip(ride, pricing)).to be_nil
      expect(Suma::Mobility::Trip.all).to have_same_ids_as(trip)
    end

    it "logs and noops if a trip with the external trip/ride id already exists (constraint violation)" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      ride = ride_json
      instance.upsert_ride_as_trip(ride, pricing)
      logs = capture_logs_from(described_class.logger, level: :debug, formatter: :json) do
        expect(instance.upsert_ride_as_trip(ride, pricing, check_dupes: false)).to be_nil
      end
      expect(logs).to include(
        include_json(message: eq("ride_already_exists")),
      )
    end

    it "does not treat the trip as ongoing (to avoid unique constraint violation)" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      Suma::Fixtures.mobility_trip.ongoing.create(member:)
      ride = ride_json
      expect(instance.upsert_ride_as_trip(ride, pricing)).to be_a(Suma::Mobility::Trip)
    end

    it "logs and noops if there is no member with that phone number" do
      pricing = Suma::Fixtures.program_pricing.create(program:, vendor_service:)
      member.update(phone: "15559998765")
      ride = ride_json
      expect_sentry_capture(type: :message, arg_matcher: eq("No member for Lyft Pass ride"))
      logs = capture_logs_from(described_class.logger, level: :debug, formatter: :json) do
        expect(instance.upsert_ride_as_trip(ride, pricing)).to be_nil
      end
      expect(logs).to include(
        include_json(message: eq("no_member_for_lyft_pass_rider")),
      )
    end
  end

  describe "invite_member" do
    let(:member) do
      Suma::Fixtures.member.
        onboarding_verified.
        registered_as_stripe_customer.
        with_cash_ledger.
        create(phone: "15552223333")
    end

    it "sends an invite to the member" do
      insert_valid_credential
      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/bulk/invite").
        with(
          body: {
            enrollment_users: [
              {custom_field_value_key_value_pairs: [], user_identifier: {phone_number: "+15552223333"}},
            ],
            ride_program_id: "5678",
          }.to_json,
          headers: {"Origin" => "https://business.lyft.com"},
        ).
        to_return(
          status: 200,
          body: {invalid_user_identifiers: []}.to_json,
          headers: {"Content-Type" => "application/json"},
        )

      instance.authenticate
      instance.invite_member(member, program_id: "5678")
      expect(req).to have_been_made
    end
  end

  describe "revoke_member" do
    let(:member) { Suma::Fixtures.member.create(phone: "15552223333") }

    it "revokes access" do
      insert_valid_credential
      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/revoke").
        with(
          body: {ride_program_id: "5678", user_identifier: {phone_number: "+15552223333"}}.to_json,
        ).to_return(status: 200, body: {}.to_json, headers: {"Content-Type" => "application/json"})

      instance.authenticate
      instance.revoke_member(member, program_id: "5678")
      expect(req).to have_been_made
    end
  end
end
# rubocop:enable Layout/LineLength
