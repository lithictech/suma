# frozen_string_literal: true

require "timecop"

require "suma/yosoy"

RSpec.describe Suma::Yosoy do
  mw_class = Class.new(Suma::Yosoy::Middleware) do
    def env_key = "yosoytest"
    def throw_key = :yosoytest
    def serialize_into_session(ao, _env) = ao.fetch(:id)
    def serialize_from_session(key, _env) = {id: key}
    def custom_reason(**extra) = response(402, **extra)
  end

  def req = Rack::MockRequest.env_for("/")
  let(:auth_obj) { {id: 1} }
  let(:coder) { Rack::Session::Cookie::Base64::Marshal.new }

  define_method :create_cookie_app do |app|
    Rack::Session::Cookie.new(app, {secret: "sekret" * 11, coder:})
  end

  define_method :create_mw do |cls: mw_class, app: nil, &block|
    app ||= block
    app = create_cookie_app(app)
    app = cls.new(app)
    app
  end

  define_method :decode_cookie do |resp|
    s = resp[1]["set-cookie"]
    s = s.delete_prefix("rack.session=")
    s = s.split(";", 2).first
    s = Rack::Utils.unescape(s)
    create_cookie_app(nil).encryptors.first.decrypt(s)
  end

  it "handles the auth flow successfully" do
    mw = create_mw do |env|
      yosoy = env.fetch("yosoytest")
      yosoy.set_authenticated_object(auth_obj)
      expect(yosoy.authenticated_object!).to eq({id: 1})
      expect(yosoy.authenticated_object?).to eq({id: 1})
      [200, {}, "ok"]
    end

    resp = mw.call(req)
    expect(resp).to match_array(
      [200, {"set-cookie" => start_with("rack.session=")}, "ok"],
    )
    expect(decode_cookie(resp)).to match(
      "session_id" => have_attributes(to_s: have_attributes(length: 64)),
      "yosoy.key" => 1,
      "yosoy.last_access" => match_time(:now),
    )
  end

  it "handles the unauthed flow successfully" do
    mw = create_mw do |env|
      yosoy = env.fetch("yosoytest")
      expect(yosoy.authenticated_object?).to be_nil
      expect(yosoy.authenticated_object!).to eq({"id" => 1})
    end

    expect(mw.call(req)).to match_array(
      [401, {"content-type" => "application/json"}, ["{\"error\":{\"status\":401,\"code\":\"unauthenticated\"}}"]],
    )
  end

  it "can log out" do
    mw = create_mw do |env|
      yosoy = env.fetch("yosoytest")
      yosoy.set_authenticated_object(auth_obj)
      env.fetch("rack.session")[:xyz] = 1
      yosoy.logout
      [200, {}, "ok"]
    end

    resp = mw.call(req)
    expect(resp).to match_array(
      [200, {"set-cookie" => start_with("rack.session=")}, "ok"],
    )
    expect(decode_cookie(resp)).to match("session_id" => have_attributes(to_s: have_attributes(length: 64)))
  end

  it "can use the throw! method" do
    mw = create_mw do |env|
      yosoy = env.fetch("yosoytest")
      yosoy.throw!(:custom_reason, x: 1)
    end

    resp = mw.call(req)
    expect(resp).to match_array(
      [402, {"content-type" => "application/json"}, ["{\"error\":{\"status\":402,\"x\":1}}"]],
    )
  end

  it "can use an explicit throw with a symbol" do
    mw = create_mw do |*|
      throw(:yosoytest, :custom_reason)
    end

    resp = mw.call(req)
    expect(resp).to match_array(
      [402, {"content-type" => "application/json"}, ["{\"error\":{\"status\":402}}"]],
    )
  end

  it "defaults to 401 if throwing without a reason" do
    mw = create_mw do |*|
      throw(:yosoytest)
    end

    resp = mw.call(req)
    expect(resp).to match_array(
      [401, {"content-type" => "application/json"}, ["{\"error\":{\"status\":401,\"code\":\"unauthenticated\"}}"]],
    )
  end

  it "errors if throwing with an unhandled reason" do
    mw = create_mw do |*|
      throw(:yosoytest, :unsupported)
    end

    expect do
      mw.call(req)
    end.to raise_error(described_class::UnhandledReason, /Use a supported reason/)
  end

  it "times out if last_access is exceeded" do
    mwclass_with_timeout = Class.new(mw_class) do
      def inactivity_timeout = 300
    end
    mw = create_mw(cls: mwclass_with_timeout) do |env|
      yosoy = env.fetch("yosoytest")
      case env[:callcount]
        when 1
          yosoy.set_authenticated_object(auth_obj)
        when 2, 3
          yosoy.authenticated_object!
        when 4
          yosoy.authenticated_object?
      end
      [200, {}, "ok"]
    end
    now = Time.now
    resp_t0 = Timecop.freeze(now) do
      env = req
      env[:callcount] = 1
      mw.call(env)
    end
    expect(resp_t0[0]).to eq(200)

    Timecop.freeze(now + 299.seconds) do
      env = req
      env["HTTP_COOKIE"] = resp_t0[1].fetch("set-cookie")
      env[:callcount] = 2
      resp_t299 = mw.call(env)
      expect(resp_t299[0]).to eq(200)
    end

    Timecop.freeze(now + 301.seconds) do
      env = req
      env["HTTP_COOKIE"] = resp_t0[1].fetch("set-cookie")
      env[:callcount] = 3
      resp_t301 = mw.call(env)
      expect(resp_t301[0]).to eq(401)

      env[:callcount] = 4
      resp_t301 = mw.call(env)
      expect(resp_t301[0]).to eq(200)
    end
  end

  it "does not check last_access if not used" do
    mw = create_mw do |env|
      yosoy = env.fetch("yosoytest")
      yosoy.set_authenticated_object(auth_obj) unless yosoy.authenticated_object?
      [200, {}, "ok"]
    end
    resp_t0 = mw.call(req)
    expect(resp_t0[0]).to eq(200)

    Timecop.freeze(5.years.from_now) do
      env = req
      env["HTTP_COOKIE"] = resp_t0[1].fetch("set-cookie")
      resp_tfuture = mw.call(env)
      expect(resp_tfuture[0]).to eq(200)
    end
  end

  it "calls on_next_request before the request, then clears" do
    calls = 0
    Suma::Yosoy.on_next_request do |proxy|
      expect(proxy).to be_a(Suma::Yosoy::Proxy)
      calls += 1
    end

    mw = create_mw do |_env|
      [200, {}, "ok"]
    end
    expect(mw.call(req)[0]).to eq(200)
    expect(mw.call(req)[0]).to eq(200)
    expect(mw.call(req)[0]).to eq(200)
    expect(calls).to eq(1)
  end

  describe described_class::BlockAuthenticatorMiddleware do
    bamwcls = Class.new(described_class) do
      def env_key = "yosoytest"
    end

    it "calls the inner app if the block passes" do
      app = bamwcls.new(->(*) { true }).new(->(*) { [200, {}, "ok"] })
      app = create_mw(app:)
      expect(app.call(req)[0]).to eq(200)
    end

    it "returns unauthenticated if the block fails" do
      app = bamwcls.new(->(*) { false }).new(->(*) { [200, {}, "ok"] })
      app = create_mw(app:)
      expect(app.call(req)[0]).to eq(401)
    end
  end
end
