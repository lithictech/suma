# frozen_string_literal: true

require "rack/test"

require "suma/api"

class Suma::API::TestService < Suma::Service
  class << self
    attr_accessor :global_shim
  end

  format :json
  require "suma/service/helpers"
  helpers Suma::Service::Helpers
  include Suma::Service::Types

  before do
    Suma::API::TestService.global_shim = {}
  end

  finally do
    Suma::API::TestService.global_shim[:sentry_scope] = Sentry.get_current_scope if
      Suma::API::TestService.global_shim
  end

  post :echo do
    present({body: params.as_json, headers: request.headers})
  end

  params do
    requires :code
  end
  get :merror do
    # Ensure merror! sets content type explicitly
    content_type "application/xml"
    merror!(403, "Hello!", code: params[:code], more: {doc_url: "http://some-place"})
  end

  params do
    requires :arg1
    requires :arg2
  end
  get :validation do
  end

  get :invalid_password do
    raise Suma::Member::InvalidPassword, "not a bunny"
  end

  get :invalid_plain do
    invalid!("this is invalid")
  end

  get :invalid_array do
    invalid!(["a is invalid", "b is invalid"])
  end

  params do
    requires :email, type: String, coerce_with: NormalizedEmail
    requires :phone, type: String, coerce_with: NormalizedPhone
    requires :arr, type: Array[String], coerce_with: CommaSepArray
    requires :numarr, type: Array[Float], coerce_with: CommaSepArray[Float]
  end
  get :custom_types do
    present({email: params[:email], phone: params[:phone], arr: params[:arr], numarr: params[:numarr]})
  end
  params do
    requires :email, type: String, coerce_with: NormalizedEmail
    requires :phone, type: String, coerce_with: NormalizedPhone
    requires :arr, type: Array[String], coerce_with: CommaSepArray
    requires :numarr, type: Array[Float], coerce_with: CommaSepArray[Float]
  end
  post :custom_types do
    status 200
    present({email: params[:email], phone: params[:phone], arr: params[:arr], numarr: params[:numarr]})
  end

  get :lock_failed do
    raise Suma::LockFailed
  end

  get :read_only_mode do
    raise Suma::Member::ReadOnlyMode, "blah"
  end

  get :unhandled do
    1 / 0
  end

  get :hello do
    status 201
    body "hi"
  end

  class MemberEntity < Grape::Entity
    expose :id
    expose :name
  end

  get :collection_array do
    present_collection [1, 2, 3]
  end

  get :collection_dataset do
    present_collection Suma::Member.dataset, with: MemberEntity
  end

  get :collection_direct do
    coll = Suma::Service::Collection.new([5, 6, 7], current_page: 10, page_count: 20, total_count: 3, last_page: false)
    present_collection coll
  end

  class MyEntity < Grape::Entity
    expose :attr do |_|
      "got it"
    end
  end

  class ExtendedCollectionEntity < Suma::Service::Collection::BaseEntity
    expose :items, with: MyEntity
  end

  get :collection_extended do
    present_collection [{attr: 5}, {attr: 6}], with: ExtendedCollectionEntity
  end

  get :caching do
    use_http_expires_caching(5.minutes)
    present [1, 2, 3]
  end

  class EtaggedEntity < Grape::Entity
    prepend Suma::Service::Entities::EtaggedMixin
    expose :field1 do |_|
      25
    end
    expose :field2 do |_|
      "abcd"
    end
    expose :x
  end

  get :etagged do
    status 200
    present ({x: Date.new(2020, 4, 23)}), with: EtaggedEntity
  end

  params do
    optional :key
  end
  get :rolecheck do
    check_role_access!(current_member, :read, params[:key] || :admin_access)
    status 200
  end

  params do
    requires :id
  end
  post :set_member do
    m = Suma::Member[params[:id]]
    ses = Suma::Fixtures.session.for(m).create
    set_session(ses)
    m2 = current_member
    present({id: m2.id})
  end

  get :current_member do
    c = current_member
    header "Test-TLS-User-Id", Thread.current[:suma_request_user]&.id&.to_s
    header "Test-TLS-Admin-Id", Thread.current[:suma_request_admin]&.id&.to_s
    present({id: c.id})
  end

  get :current_member_safe do
    c = current_member?
    present({id: c&.id})
  end

  get :admin_member do
    c = admin_member
    present({id: c.id})
  end

  get :admin_member_safe do
    c = admin_member?
    present({id: c&.id})
  end

  params do
    requires :file, type: File
  end
  post :fileparam do
    present params[:file]
  end

  class LanguageWithExposeEntity < Suma::Service::Entities::Base
    expose_translated :name
  end

  class LanguageWithBlockExposureEntity < Suma::Service::Entities::Base
    expose_translated :othername, &self.delegate_to(:name)
  end
  get :language_with_exposure do
    p = Suma::Fixtures.product.create
    p.name.update(en: "English", es: "Spanish")
    present(p, with: LanguageWithExposeEntity)
    status 200
  end

  get :language_with_block do
    p = Suma::Fixtures.product.create
    p.name.update(en: "English", es: "Spanish")
    present(p, with: LanguageWithBlockExposureEntity)
    status 200
  end

  class ProductEntity < Suma::Service::Entities::Base
    expose_translated :name
  end
  get :markdown_translation do
    (product = Suma::Commerce::Product[params[:id]]) or forbidden!
    present(product, with: ProductEntity)
    status 200
  end

  Rack::Attack.throttle("/test/rate_limited", limit: 1, period: 30) do |req|
    req.path == "/rate_limited" ? "test" : nil
  end
  get :rate_limited do
    status 200
    present {}
  end

  params do
    requires :behavior, values: ["stream", "present"]
    requires :addcache, type: Boolean
  end
  get :streamer do
    header "Cache-Control", "public" if params[:addcache]
    header "Transfer-Encoding", "compress"
    # noinspection RubyCaseWithoutElseBlockInspection
    case params[:behavior]
      when "stream"
        header "Content-Length", "666"
        header "Transfer-Encoding", "nope"
        stream ["h", "e", "l", "l", "o"]
      when "present"
        present({})
    end
  end

  params do
    optional :fk, type: JSON do
      optional :id
    end
    optional :fk_arr, type: Array do
      optional :id
      optional :sub_fk, type: JSON do
        optional :id
      end
    end
  end
  post :declared_provided_params do
    p = declared_and_provided_params(params)
    present p
  end
end

RSpec.describe Suma::Service, :db do
  include Rack::Test::Methods

  before(:all) do
    @devmode = described_class.devmode
    @enforce_ssl = described_class.enforce_ssl
  end

  after(:all) do
    described_class.devmode = @devmode
    described_class.enforce_ssl = @enforce_ssl
  end

  before(:each) do
    described_class.devmode = true
    described_class.enforce_ssl = false
  end

  let(:app) { Suma::API::TestService.build_app }

  it "redirects requests if SSL is enforced" do
    described_class.enforce_ssl = true

    get "/hello"
    expect(last_response).to have_status(301)
  end

  it "always clears request_user after the request" do
    Thread.current[:suma_request_user] = 5
    Thread.current[:suma_request_admin] = 6
    get "/hello"
    expect(last_response).to have_status(201)
    expect(Thread.current[:suma_request_user]).to be_nil
    expect(Thread.current[:suma_request_admin]).to be_nil

    Thread.current[:suma_request_user] = 5
    Thread.current[:suma_request_admin] = 6
    get "/merror", code: "forbidden"
    expect(last_response).to have_status(403)
    expect(Thread.current[:suma_request_user]).to be_nil
    expect(Thread.current[:suma_request_admin]).to be_nil
  end

  it "uses a consistent error shape for manual errors (merror!)", reset_configuration: described_class do
    described_class.verify_localized_error_codes = false
    get "/merror?code=test_err"
    expect(last_response).to have_status(403)
    expect(last_response_json_body).to eq(
      error: {doc_url: "http://some-place", message: "Hello!", status: 403, code: "test_err"},
    )
  end

  it "uses a consistent error shape for validation errors" do
    get "/validation"
    expect(last_response).to have_status(400)
    expect(last_response_json_body).to eq(
      error: {
        code: "validation_error",
        errors: ["arg1 is missing", "arg2 is missing"],
        # Upcase the first letter, since this is probably going into the UI.
        message: "Arg1 is missing, arg2 is missing",
        status: 400,
      },
    )

    get "/invalid_password"
    expect(last_response).to have_status(400)
    expect(last_response_json_body).to eq(
      error: {code: "validation_error", errors: ["not a bunny"], message: "Not a bunny", status: 400},
    )
  end

  it "derives a message from a validation error string" do
    get "/invalid_plain"
    expect(last_response).to have_status(400)
    expect(last_response_json_body).to eq(
      error: {code: "validation_error", errors: ["this is invalid"], message: "This is invalid", status: 400},
    )
  end

  it "derives a message from an array of validation errors" do
    get "/invalid_array"
    expect(last_response).to have_status(400)
    expect(last_response_json_body).to eq(
      error: {
        code: "validation_error",
        errors: ["a is invalid", "b is invalid"],
        message: "A is invalid, b is invalid",
        status: 400,
      },
    )
  end

  it "uses a consistent shape for LockFailed errors" do
    get "/lock_failed"
    expect(last_response).to have_status(409)
    expect(last_response_json_body).to match(
      error: hash_including(
        code: "lock_failed",
        status: 409,
      ),
    )
  end

  it "uses a consistent shape for ReadOnlyMode errors" do
    get "/read_only_mode"
    expect(last_response).to have_status(409)
    expect(last_response_json_body).to match(
      error: hash_including(
        code: "blah",
        status: 409,
      ),
    )
  end

  it "uses a consistent error shape for unhandled errors (devmode: off)", reset_configuration: Suma::Sentry do
    Suma::Sentry.reset_configuration(dsn: "foo")
    expect(Sentry).to receive(:capture_exception)

    described_class.devmode = false

    get "/unhandled"

    expect(last_response).to have_status(500)
    expect(last_response_json_body).to match(error: match(
      error_id: match(/[a-z0-9-]+/),
      error_signature: match(/[a-z0-9]+/),
      message: match(/An internal error occurred of type [a-z0-9]+\. Error ID: [a-z0-9-]+/),
      status: 500,
      code: "api_error",
    ))
    expect(last_response_json_body[:error]).to_not include(:backtrace)
  end

  it "uses a consistent error shape for unhandled errors (devmode: on)" do
    described_class.devmode = true

    get "/unhandled"

    expect(last_response).to have_status(500)
    expect(last_response_json_body).to match(error: match(
      backtrace: %r{suma/service_spec\.rb:},
      error_id: match(/[a-z0-9-]+/),
      error_signature: match(/[a-z0-9]+/),
      message: "divided by 0",
      status: 500,
      code: "api_error",
    ))
  end

  describe "error code localization", reset_configuration: described_class do
    it "does not error if code are localized" do
      get "/merror?code=auth_conflict"
      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "auth_conflict"))
    end

    it "errors if the code is not localized" do
      get "/merror?code=thisisabadcode"
      expect(last_response).to have_status(500)
      expect(last_response).to have_json_body.that_includes(error: include(code: "unhandled_error"))
    end

    it "does not error if not enabled" do
      described_class.verify_localized_error_codes = false
      get "/merror?code=thisisabadcode"
      expect(last_response).to have_status(403)
    end
  end

  it "returns 405s as-is" do
    described_class.devmode = true

    put "/hello"

    expect(last_response).to have_status(405)
    expect(last_response).to have_json_body.that_includes(error: "405 Not Allowed")
  end

  it "always creates a session for unauthed members" do
    get "/hello"

    expect(last_response).to have_status(201)
    expect(last_session_id).to be_present
  end

  describe "endpoint caching" do
    after(:all) do
      described_class.endpoint_caching = false
    end

    it "can cache via an Expires header" do
      described_class.endpoint_caching = true

      get "/caching"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Expires", "Cache-Control" => "public")
      expect(Time.parse(last_response.headers["Expires"])).to be_within(1.second).of(5.minutes.from_now)
    end

    it "does not cache if endpoint caching is disabled" do
      described_class.endpoint_caching = false

      get "/caching"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to_not include("Expires")
    end
  end

  describe "collections" do
    it "can wrap an array of items" do
      get "/collection_array"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        object: "list",
        items: [1, 2, 3],
        current_page: 1,
        has_more: false,
        page_count: 1,
        total_count: 3,
      )
    end

    it "can wrap a Sequel dataset" do
      member = Suma::Fixtures.member.create

      get "/collection_dataset"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        object: "list",
        items: [{id: member.id, name: member.name}],
        current_page: 1,
        has_more: false,
        page_count: 1,
        total_count: 1,
      )
    end

    it "can represent a Collection directly" do
      get "/collection_direct"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        object: "list",
        items: [5, 6, 7],
        current_page: 10,
        has_more: true,
        page_count: 20,
        total_count: 3,
      )
    end

    it "can use a custom collection entity" do
      get "/collection_extended"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        object: "list",
        items: [{attr: "got it"}, {attr: "got it"}],
        total_count: 2,
      )
    end
  end

  it "adds CORS_ORIGINS env into configured origins" do
    described_class.reset_configuration(cors_origins: ["a.b", "x.y", /suma-web-staging(-pr-\d+)?\.herokuapp\.com/])
    expect(described_class.cors_origins).to include(
      /localhost:\d+/, "a.b", "x.y", /suma-web-staging(-pr-\d+)?\.herokuapp\.com/,
    )
  end

  describe "Sentry integration" do
    around(:each) do |example|
      # We need to fake doing what Sentry would be doing for initialization,
      # so we can assert it has the right data in its scope.
      config = Sentry::Configuration.new
      client = Sentry::Client.new(config)
      hub = Sentry::Hub.new(client, Sentry::Scope.new)
      expect(Sentry).to_not be_initialized
      Sentry.instance_variable_set(:@main_hub, hub)
      expect(Sentry).to be_initialized
      Sentry.instance_variable_set(:@session_flusher, Sentry::SessionFlusher.new(config, client))
      example.run
    ensure
      Sentry.instance_variable_set(:@main_hub, nil)
      expect(Sentry).to_not be_initialized
      Sentry.instance_variable_set(:@session_flusher, nil)
    end

    it "reports errors to Sentry if devmode is off and Sentry is enabled" do
      described_class.devmode = false
      Suma::Sentry.dsn = "foo"
      expect(Sentry).to receive(:capture_exception).
        with(ZeroDivisionError, tags: include(:error_id, :error_signature))

      get "/unhandled"
      expect(last_response).to have_status(500)
    end

    it "does not report errors to Sentry if devmode is on and Sentry is enabled" do
      described_class.devmode = true
      Suma::Sentry.dsn = "foo"
      expect(Sentry).to_not receive(:capture_exception)

      get "/unhandled"
      expect(last_response).to have_status(500)
    end

    it "does not report errors to Sentry if devmode is on and Sentry is disabled" do
      described_class.devmode = true
      Suma::Sentry.reset_configuration
      expect(Sentry).to_not receive(:capture_exception)

      get "/unhandled"
      expect(last_response).to have_status(500)
    end

    it "does not report errors to Sentry if devmode is off and Sentry is disabled" do
      described_class.devmode = false
      Suma::Sentry.reset_configuration
      expect(Sentry).to_not receive(:capture_exception)

      get "/unhandled"
      expect(last_response).to have_status(500)
    end

    it "captures context for unauthed members" do
      get "/hello?world=1"
      expect(last_response).to have_status(201)

      expect(Suma::API::TestService.global_shim[:sentry_scope]).to have_attributes(
        user: include(ip_address: "127.0.0.1"),
        tags: include(host: "example.org", method: "GET", path: "/hello", query: "world=1"),
      )
    end

    it "captures context for authed members" do
      member = Suma::Fixtures.member.create
      login_as(member)

      get "/hello?world=1"
      expect(last_response).to have_status(201)

      expect(Suma::API::TestService.global_shim[:sentry_scope]).to have_attributes(
        user: include(
          ip_address: "127.0.0.1",
          id: member.id,
          email: member.email,
          name: member.name,
        ),
        tags: include(
          host: "example.org",
          method: "GET",
          path: "/hello",
          query: "world=1",
          "member.email" => member.email,
        ),
      )
    end

    it "captures context for admins" do
      admin = Suma::Fixtures.member.admin.create
      member = Suma::Fixtures.member.create
      impersonate(admin:, target: member)

      get "/hello?world=1"
      expect(last_response).to have_status(201)

      expect(Suma::API::TestService.global_shim[:sentry_scope]).to have_attributes(
        user: include(
          admin_id: admin.id,
          id: member.id,
        ),
        tags: include(
          "member.email" => member.email,
          "admin.email" => admin.email,
        ),
      )
    end
  end

  describe "etag mixin" do
    it "hashes the rendered entity" do
      get "/etagged"

      expect(last_response).to have_status(200)
      expect(last_response.body).to eq(
        '{"field1":25,"field2":"abcd","x":"2020-04-23","etag":"db41e3e0da219ca43359a8581cdb74b1"}',
      )
    end
  end

  describe "custom types" do
    it "works with custom types" do
      get "/custom_types?email= x@Y.Z &phone=555-111-2222&arr=1,2,a&numarr=1,2,3"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        email: "x@y.z",
        phone: "15551112222",
        arr: ["1", "2", "a"],
        numarr: [1, 2, 3],
      )
    end

    it "POST works with custom types" do
      post "/custom_types", {email: " x@Y.Z ", phone: "555-111-2222", arr: "1,2,a", numarr: "1,2,3"}
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        email: "x@y.z",
        phone: "15551112222",
        arr: ["1", "2", "a"],
        numarr: [1, 2, 3],
      )
    end

    it "POST works with actual arrays" do
      post "/custom_types", {email: " x@Y.Z ", phone: "555-111-2222", arr: ["1", "2", "a"], numarr: [1, 2, 3]}
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        email: "x@y.z",
        phone: "15551112222",
        arr: ["1", "2", "a"],
        numarr: [1, 2, 3],
      )
    end
  end

  describe "role checking" do
    let(:member) { Suma::Fixtures.member.create }

    it "passes if the member has access" do
      member.add_role(Suma::Role.cache.readonly_admin)
      login_as(member)
      get "/rolecheck"
      expect(last_response).to have_status(200)
    end

    it "errors if no role access key with that name exists" do
      login_as(member)
      get "/rolecheck", key: "foo"
      expect(last_response).to have_status(500)
    end

    it "403s if the member does not have access" do
      login_as(member)
      get "/rolecheck"
      expect(last_response).to have_json_body.that_includes(
        error: {
          message: "You are not permitted to read on admin_access",
          status: 403,
          code: "role_check",
        },
      )
    end
  end

  describe "current_member" do
    let(:member) { Suma::Fixtures.member.create }
    let(:admin) { Suma::Fixtures.member.admin.create }

    it "looks up the logged in user" do
      login_as(member)
      get "/current_member"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id)
    end

    it "sets the custom in thread local and clears it after the request" do
      login_as(member)
      impersonate(admin:, target: member)
      get "/current_member"
      expect(last_response).to have_status(200)
      expect(last_response.headers["Test-TLS-User-Id"]).to eq(member.id.to_s)
      expect(last_response.headers["Test-TLS-Admin-Id"]).to eq(admin.id.to_s)
      expect(Thread.current[:request_user]).to be_nil
      expect(Thread.current[:request_admin]).to be_nil
    end

    it "401s if no logged in user" do
      get "/current_member"
      expect(last_response).to have_status(401)
    end

    it "401s if the user is deleted" do
      login_as(member)
      member.soft_delete
      get "/current_member"
      expect(last_response).to have_status(401)
    end

    it "401s if the session is logged out" do
      session = Suma::Fixtures.session.for(member).create
      login_as(session)
      session.mark_logged_out.save_changes
      get "/current_member"
      expect(last_response).to have_status(401)
    end

    describe "session validation", reset_configuration: described_class do
      before(:each) do
        post "/set_member", id: member.id
        expect(last_response).to have_status(201)
        # At this point, the cookie will have a 30 day expiration, but now we need to check the 'user auth age' logic.
        # Set the max_session_age (used for that check) to be shorter than it was,
        # since trying to do this all through the front door is extremely hard (Rack::Test won't send the expired cookie).
        # The shortened max_session_age here means 1) the expires_at of the cookie is still valid, which is good
        # because we want to assume the expires_at is always valid for this, and
        # 2) we can use Timecop to check the rest of the behavior, around extending the auth date
        # and failing if it's too old.
        described_class.max_session_age = 60
        # Sanity check to make sure everything works.
        get "/current_member"
        expect(last_response).to have_status(200)
      end

      it "fails if the user authed more than the session age ago" do
        Timecop.travel(90.seconds.from_now) { get "/current_member" }
        expect(last_response).to have_status(401)
      end

      it "sets the last auth time to extend the session duration on each authed request" do
        Timecop.travel(30.seconds.from_now) { get "/current_member" }
        expect(last_response).to have_status(200)
        Timecop.travel(61.seconds.from_now) { get "/current_member" }
        expect(last_response).to have_status(200)
        Timecop.travel(90.seconds.from_now) { get "/current_member" }
        expect(last_response).to have_status(200)
        Timecop.travel(125.seconds.from_now) { get "/current_member" }
        expect(last_response).to have_status(200)
        Timecop.travel(200.seconds.from_now) { get "/current_member" }
        expect(last_response).to have_status(401)
      end
    end

    it "returns the impersonated user (even if deleted)" do
      impersonate(admin:, target: member)
      get "/current_member"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id)
    end

    it "401s if the admin impersonating a user is deleted" do
      impersonate(admin:, target: member)
      admin.soft_delete
      get "/current_member"
      expect(last_response).to have_status(401)
    end

    it "401s if the admin impersonating a user does not have the admin role" do
      impersonate(admin:, target: member)
      admin.remove_all_roles
      get "/current_member"
      expect(last_response).to have_status(401)
    end
  end

  describe "current_member?" do
    let(:member) { Suma::Fixtures.member.create }
    let(:admin) { Suma::Fixtures.member.admin.create }

    it "looks up the logged in user" do
      login_as(member)
      get "/current_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id)
    end

    it "returns nil if no logged in user" do
      get "/current_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: nil)
    end

    it "401s and clears cookies if the user is deleted" do
      login_as(member)
      member.soft_delete
      get "/current_member_safe"
      expect(last_response).to have_status(401)
    end

    it "returns the impersonated user (even if deleted)" do
      impersonate(admin:, target: member)
      get "/current_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id)
    end

    it "401s if the admin impersonating a user is deleted/missing role" do
      impersonate(admin:, target: member)
      admin.soft_delete
      get "/current_member_safe"
      expect(last_response).to have_status(401)
    end
  end

  describe "admin_member" do
    let(:member) { Suma::Fixtures.member.create }
    let(:admin) { Suma::Fixtures.member.admin.create }

    it "looks up the logged in admin" do
      login_as(admin)
      get "/admin_member"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end

    it "401s if no logged in admin" do
      get "/admin_member"
      expect(last_response).to have_status(401)
    end

    it "401s if the admin is deleted" do
      login_as(admin)
      admin.soft_delete
      get "/admin_member"
      expect(last_response).to have_status(401)
    end

    it "401s if the admin does not have the role" do
      login_as(admin)
      admin.remove_all_roles
      get "/admin_member"
      expect(last_response).to have_status(401)
    end

    it "returns the admin, even while impersonating" do
      impersonate(admin:, target: member)
      get "/admin_member"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end
  end

  describe "admin_member?" do
    let(:member) { Suma::Fixtures.member.create }
    let(:admin) { Suma::Fixtures.member.admin.create }

    it "looks up the logged in admin" do
      login_as(admin)
      get "/admin_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end

    it "returns nil no logged in admin" do
      get "/admin_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: nil)
    end

    it "401s if the admin is deleted" do
      login_as(admin)
      admin.soft_delete
      get "/admin_member_safe"
      expect(last_response).to have_status(401)
    end

    it "uses nil if the admin does not have the role" do
      login_as(admin)
      admin.remove_all_roles
      get "/admin_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: nil)
    end

    it "returns the admin, even while impersonating" do
      impersonate(admin:, target: member)
      get "/admin_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end
  end

  describe "BaseEntity" do
    describe "timezone helper" do
      let(:t) { Time.parse("2021-09-16T12:41:23Z") }

      it "renders using a path to a timezone" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :time, &self.timezone(:member, :mytz)
        end
        r = ent.represent(
          instance_double("Obj",
                          time: t,
                          member: instance_double("Member", mytz: "America/New_York"),),
        )
        expect(r.as_json[:time]).to eq("2021-09-16T08:41:23-04:00")
      end

      it "renders using a path to an object with a :timezone method" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :time, &self.timezone(:member)
        end
        r = ent.represent(
          instance_double("Obj",
                          time: t,
                          member: instance_double("Member", timezone: "America/New_York"),),
        )
        expect(r.as_json[:time]).to eq("2021-09-16T08:41:23-04:00")
      end

      it "renders using a path to an object with a :time_zone method" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :time, &self.timezone(:member)
        end
        r = ent.represent(
          instance_double("Obj",
                          time: t,
                          member: instance_double("Member", time_zone: "America/New_York"),),
        )
        expect(r.as_json[:time]).to eq("2021-09-16T08:41:23-04:00")
      end

      it "uses the default rendering if any item in the path is missing" do
        ts = t.iso8601
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :time, &self.timezone(:member, :mytz)
        end

        d = instance_double("Obj", time: t)
        expect(d).to receive(:member).and_raise(NoMethodError)
        r = ent.represent(d)
        expect(r.as_json[:time]).to eq(ts)

        d = instance_double("Obj", time: t, member: instance_double("Member"))
        expect(d.member).to receive(:mytz).and_raise(NoMethodError)
        r = ent.represent(d)
        expect(r.as_json[:time]).to eq(ts)

        d = instance_double("Obj", time: t, member: instance_double("Member", mytz: nil))
        r = ent.represent(d)
        expect(r.as_json[:time]).to eq(ts)

        d = instance_double("Obj", time: t, member: instance_double("Member", mytz: ""))
        r = ent.represent(d)
        expect(r.as_json[:time]).to eq(ts)
      end

      it "can pull from an explicit field" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :time_not_here, &self.timezone(:member, field: :mytime)
        end
        r = ent.represent(
          instance_double("Obj",
                          mytime: t,
                          member: instance_double("Member", time_zone: "America/New_York"),),
        )
        expect(r.as_json[:time_not_here]).to eq("2021-09-16T08:41:23-04:00")
      end
    end

    describe "delegate_to" do
      xcls = Class.new(Suma::TypedStruct) do
        attr_accessor :a, :b, :c
      end

      let(:x) { xcls.new(a: xcls.new(b: xcls.new(c: 1))) }

      it "delegates to the given fields" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :z, &self.delegate_to(:a, :b, :c)
        end
        r = ent.represent(x)
        expect(r.as_json.to_h).to eq({z: 1})
      end

      it "is nil if safe" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :z, &self.delegate_to(:yyy, safe: true)
        end
        r = ent.represent(x)
        expect(r.as_json.to_h).to eq({z: nil})
      end

      it "can give a safe_with_default" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :z, &self.delegate_to(:yyy, safe_with_default: 100)
        end
        r = ent.represent(x)
        expect(r.as_json.to_h).to eq({z: 100})
      end

      it "raises for an invalid path if unsafe" do
        ent = Class.new(Suma::Service::Entities::Base) do
          expose :z, &self.delegate_to(:yyy)
        end
        expect { ent.represent(x).as_json.to_h }.to raise_error(NoMethodError, /undefined method `yyy'/)
      end
    end
  end

  describe "localization" do
    it "sets the language based on the accept header and can use expose_translated" do
      expect(SequelTranslatedText.language).to be_nil
      header "Accept-Language", "es-AR"
      get "/language_with_exposure"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: "Spanish")
    end

    it "can use expose_translated with a block" do
      get "/language_with_block"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(othername: "English")
    end

    it "includes a ZWNJ if the text in the database is probably markdown" do
      p = Suma::Fixtures.product.create
      p.name.update(en: "Tacos")

      get "/markdown_translation", id: p.id
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: "Tacos")

      p.name.update(en: "Ta**co**s")

      get "/markdown_translation", id: p.id
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: "\u200CTa**co**s")
    end
  end

  describe "rate limiting", reset_configuration: Suma::RackAttack do
    it "returns a 429 with headers and body" do
      Suma::RackAttack.reset_configuration(enabled: true)
      Timecop.freeze("2024-01-01T12:00:12Z") do
        get "/rate_limited"
        expect(last_response).to have_status(200)
        get "/rate_limited"
        expect(last_response).to have_status(429)
        expect(last_response.headers).to include("Retry-After" => "18")
        expect(last_response).to have_json_body.
          that_includes(
            error: {
              retry_after: "18",
              message: "Rate limited",
              status: 429,
              code: "too_many_requests",
            },
          )
      end
    end
  end

  describe "test helpers" do
    it "does not try to turn a file upload into json" do
      file = Rack::Test::UploadedFile.new(__FILE__, "text/csv")
      post "/fileparam", {file:}
      expect(last_response).to have_status(201)
      expect(last_response).to have_json_body.that_includes(type: "text/csv", name: "file", filename: "service_spec.rb")
    end

    it "does not modify string requests" do
      # If we re-encode this it'd be a string, not a hash
      post "/echo", '{"x":1}', {"CONTENT_TYPE" => "application/json"}
      expect(last_response).to have_status(201)
      expect(last_response).to have_json_body.that_includes(body: {x: 1})
    end

    it "only serializes json content type" do
      post "/echo", {x: 1}, {"CONTENT_TYPE" => "application/x-www-form-urlencoded"}
      expect(last_response).to have_status(201)
      expect(last_response).to have_json_body.that_includes(body: {x: "1"})
    end
  end

  describe "patches" do
    describe "stream" do
      it "does not modify non-stream behavior" do
        get "/streamer?behavior=present&addcache=0"

        expect(last_response).to have_status(200)
        expect(last_response.body).to eq("{}")
        expect(last_response.headers).to include(
          "Content-Length" => "2",
          "Transfer-Encoding" => "compress",
        )
      end

      it "does not modify default behavior" do
        get "/streamer?behavior=stream&addcache=0"

        expect(last_response).to have_status(200)
        expect(last_response.body).to eq("hello")
        expect(last_response.headers).to include("Cache-Control" => "no-cache")
        expect(last_response.headers).to_not have_key("Transfer-Encoding")
      end

      it "restores the cache-control header" do
        get "/streamer?behavior=stream&addcache=1"

        expect(last_response).to have_status(200)
        expect(last_response.body).to eq("hello")
        expect(last_response.headers).to include("Cache-Control" => "public")
        expect(last_response.headers).to_not have_key("Transfer-Encoding")
      end
    end
  end

  describe "declared_and_provided_params" do
    it "returns only declared and provided params" do
      post "/declared_provided_params",
           {
             other: 1,
             other2: nil,
             other_fk: {id: 1},
             fk: {id: 2, name: "a"},
             fk_arr: [
               {id: 3, name: "b"},
               {id: 4, sub_fk: {id: 5, name: "c"}},
               {id: 6, sub_fk: nil},
               {id: nil},
             ],
           }

      expect(last_response).to have_status(201)
      expect(last_response_json_body).to eq(
        {
          fk: {id: 2},
          fk_arr: [
            {id: 3},
            {id: 4, sub_fk: {id: 5}},
            {id: 6, sub_fk: nil},
            {id: nil},
          ],
        },
      )
    end
  end

  describe "puma" do
    it "knows if it is in master or worker mode" do
      expect(described_class).to be_puma_parent
      expect(described_class).to_not be_puma_worker
      ENV["PUMA_WORKER"] = "1"
      expect(described_class).to_not be_puma_parent
      expect(described_class).to be_puma_worker
    end
  end

  describe "encode and decode cookie" do
    it "encodes and decodes" do
      h = {"x" => 1}
      s = described_class.encode_cookie(h)
      expect(s).to be_a(String)
      h2 = described_class.decode_cookie(s)
      expect(h2).to eq(h)
    end
  end
end
