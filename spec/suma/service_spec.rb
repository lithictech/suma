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
    Suma::API::TestService.global_shim[:sentry_scope] = Sentry.get_current_scope
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
  end
  get :custom_types do
    present({email: params[:email], phone: params[:phone], arr: params[:arr]})
  end
  params do
    requires :email, type: String, coerce_with: NormalizedEmail
    requires :phone, type: String, coerce_with: NormalizedPhone
    requires :arr, type: Array[String], coerce_with: CommaSepArray
  end
  post :custom_types do
    status 200
    present({email: params[:email], phone: params[:phone], arr: params[:arr]})
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
    expose :note
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

  get :rolecheck do
    check_role!(current_member, "testing")
    status 200
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

  it "uses a consistent error shape for manual errors (merror!)" do
    described_class.localized_error_codes = nil
    get "/merror?code=test_err"
    expect(last_response).to have_status(403)
    expect(last_response_json_body).to eq(
      error: {doc_url: "http://some-place", message: "Hello!", status: 403, code: "test_err"},
    )
  ensure
    described_class.reset_configuration
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

  it "uses a consistent error shape for unhandled errors (devmode: off)" do
    Suma::Sentry.dsn = "foo"
    Suma::Sentry.run_after_configured_hooks
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
  ensure
    Suma::Sentry.reset_configuration
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

  describe "error code localization" do
    after(:each) do
      described_class.reset_configuration
    end

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
      described_class.localized_error_codes = nil
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
        items: [{id: member.id, note: member.note}],
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
    described_class.cors_origins = ["a.b", "x.y", /suma-web-staging(-pr-\d+)?\.herokuapp\.com/]
    described_class.run_after_configured_hooks
    expect(described_class.cors_origins).to include(
      /localhost:\d+/, "a.b", "x.y", /suma-web-staging(-pr-\d+)?\.herokuapp\.com/,
    )
  end

  describe "Sentry integration" do
    before(:each) do
      # We need to fake doing what Sentry would be doing for initialization,
      # so we can assert it has the right data in its scope.
      hub = Sentry::Hub.new(
        Sentry::Client.new(Sentry::Configuration.new),
        Sentry::Scope.new,
      )
      expect(Sentry).to_not be_initialized
      Sentry.instance_variable_set(:@main_hub, hub)
      expect(Sentry).to be_initialized
    end

    after(:each) do
      Sentry.instance_variable_set(:@main_hub, nil)
      expect(Sentry).to_not be_initialized
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
      get "/custom_types?email= x@Y.Z &phone=555-111-2222&arr=1,2,a"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        email: "x@y.z",
        phone: "15551112222",
        arr: ["1", "2", "a"],
      )
    end

    it "POST works with custom types" do
      post "/custom_types", {email: " x@Y.Z ", phone: "555-111-2222", arr: "1,2,a"}
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        email: "x@y.z",
        phone: "15551112222",
        arr: ["1", "2", "a"],
      )
    end

    it "POST works with actual arrays" do
      post "/custom_types", {email: " x@Y.Z ", phone: "555-111-2222", arr: ["1", "2", "a"]}
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        email: "x@y.z",
        phone: "15551112222",
        arr: ["1", "2", "a"],
      )
    end
  end

  describe "role checking" do
    let(:member) { Suma::Fixtures.member.create }

    it "passes if the member has a matching role" do
      member.add_role(Suma::Role.create(name: "testing"))
      login_as(member)
      get "/rolecheck"
      expect(last_response).to have_status(200)
    end

    it "errors if no role with that name exists" do
      login_as(member)
      get "/rolecheck"
      expect(last_response).to have_status(500)
    end

    it "errors if the member does not have a matching role" do
      Suma::Role.create(name: "testing")
      login_as(member)
      get "/rolecheck"
      expect(last_response).to have_json_body.that_includes(
        error: {
          message: "Sorry, this action is unavailable.",
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

    it "errors if no logged in user" do
      get "/current_member"
      expect(last_response).to have_status(401)
    end

    it "errors and clears cookies if the user is deleted" do
      login_as(member)
      member.soft_delete
      get "/current_member"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
    end

    it "returns the impersonated user (even if deleted)" do
      impersonate(admin:, target: member)
      get "/current_member"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id)
    end

    it "errors and clears cookies if the admin impersonating a user is deleted" do
      impersonate(admin:, target: member)
      admin.soft_delete
      get "/current_member"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
    end

    it "errors if the admin impersonating a user does not have the admin role" do
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

    it "errors and clears cookies if the user is deleted" do
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

    it "errors if the admin impersonating a user is deleted/missing role" do
      impersonate(admin:, target: member)
      admin.soft_delete
      get "/current_member_safe"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
    end
  end

  describe "admin_member" do
    let(:member) { Suma::Fixtures.member.create }
    let(:admin) { Suma::Fixtures.member.admin.create }

    it "looks up the logged in admin" do
      login_as_admin(admin)
      get "/admin_member"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end

    it "errors if no logged in admin" do
      get "/admin_member"
      expect(last_response).to have_status(401)
    end

    it "errors and clears cookies if the admin is deleted" do
      login_as_admin(admin)
      admin.soft_delete
      get "/admin_member"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
    end

    it "errors and clears cookies if the admin does not have the role" do
      login_as_admin(admin)
      admin.remove_all_roles
      get "/admin_member"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
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
      login_as_admin(admin)
      get "/admin_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end

    it "returns nil no logged in admin" do
      get "/admin_member_safe"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: nil)
    end

    it "errors and clears cookies if the admin is deleted" do
      login_as_admin(admin)
      admin.soft_delete
      get "/admin_member_safe"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
    end

    it "errors and clears cookies if the admin does not have the role" do
      login_as_admin(admin)
      admin.remove_all_roles
      get "/admin_member_safe"
      expect(last_response).to have_status(401)
      expect(last_response.cookies).to be_empty
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
end
