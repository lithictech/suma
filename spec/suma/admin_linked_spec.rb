# frozen_string_literal: true

RSpec.describe Suma::AdminLinked, reset_configuration: Suma do
  it "has an absolute admin link" do
    Suma.admin_url = "http://localhost/admin"
    cls = Class.new do
      include Suma::AdminLinked
      def rel_admin_link = "/foo"
    end
    expect(cls.new.admin_link).to eq("http://localhost/admin/foo")
  end

  it "raises if rel_admin_link is not implemented" do
    cls = Class.new do
      include Suma::AdminLinked
    end
    expect { cls.new.admin_link }.to raise_error(NotImplementedError, /must implement :rel_admin_link/)
  end

  it "can set a rooted admin link" do
    Suma.admin_url = "http://localhost/admin"
    cls = Class.new do
      include Suma::AdminLinked
      def rel_admin_link = "/foo"
    end
    expect(cls.new.rooted_admin_link).to eq("/admin/foo")

    Suma.admin_url = "http://localhost:1000"
    cls = Class.new do
      include Suma::AdminLinked
      def rel_admin_link = "/foo"
    end
    expect(cls.new.rooted_admin_link).to eq("/foo")
  end
end
