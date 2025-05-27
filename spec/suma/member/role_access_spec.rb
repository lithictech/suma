# frozen_string_literal: true

RSpec.describe "Suma::Member::RoleAccess", :db do
  let(:described_class) { Suma::Member::RoleAccess }

  it "lets admins do everything" do
    member = Suma::Fixtures.member.admin.create
    expect(member.role_access { read?(upload_files) }).to be(true)
    expect(member.role_access { read?(admin_access) }).to be(true)
    expect(member.role_access { read?(admin_members) }).to be(true)
    expect(member.role_access { read?(admin_commerce) }).to be(true)
    expect(member.role_access { read?(admin_management) }).to be(true)
    expect(member.role_access { read?(marketing_sms) }).to be(true)
    expect(member.role_access { write?(marketing_sms) }).to be(true)
  end

  it "lets non-admins do nothing extra" do
    member = Suma::Fixtures.member.create
    expect(member.role_access { read?(upload_files) }).to be(false)
    expect(member.role_access { read?(admin_access) }).to be(false)
    expect(member.role_access { read?(admin_members) }).to be(false)
    expect(member.role_access { read?(admin_commerce) }).to be(false)
    expect(member.role_access { read?(admin_management) }).to be(false)
  end

  it "lets image uploaders upload" do
    member = Suma::Fixtures.member.create
    member.add_role(Suma::Role.cache.upload_files)
    expect(member.role_access { read?(upload_files) }).to be(true)
    expect(member.role_access { read?(admin_access) }).to be(false)
    expect(member.role_access { read?(admin_members) }).to be(false)
    expect(member.role_access { read?(admin_commerce) }).to be(false)
    expect(member.role_access { read?(admin_management) }).to be(false)
  end

  it "lets onboarding managers access admin" do
    member = Suma::Fixtures.member.create
    member.add_role(Suma::Role.cache.onboarding_manager)
    expect(member.role_access { read?(upload_files) }).to be(false)
    expect(member.role_access { read?(admin_access) }).to be(true)
    expect(member.role_access { read?(admin_members) }).to be(true)
    expect(member.role_access { write?(admin_members) }).to be(true)
    expect(member.role_access { read?(admin_commerce) }).to be(false)
    expect(member.role_access { write?(admin_commerce) }).to be(false)
    expect(member.role_access { read?(admin_management) }).to be(false)
  end

  it "lets sms marketers access admin and send messages" do
    member = Suma::Fixtures.member.create
    member.add_role(Suma::Role.cache.sms_marketing)
    expect(member.role_access { read?(upload_files) }).to be(false)
    expect(member.role_access { read?(admin_access) }).to be(true)
    expect(member.role_access { read?(admin_members) }).to be(true)
    expect(member.role_access { write?(admin_members) }).to be(false)
    expect(member.role_access { read?(admin_commerce) }).to be(false)
    expect(member.role_access { read?(admin_management) }).to be(false)
    expect(member.role_access { read?(marketing_sms) }).to be(true)
    expect(member.role_access { write?(marketing_sms) }).to be(true)
  end

  it "uses maximum access when multiple roles are present" do
    member = Suma::Fixtures.member.create
    member.add_role Suma::Role.cache.readonly_admin
    expect(member.role_access { read?(admin_access) }).to be(true)
    expect(member.role_access { read?(admin_members) }).to be(true)
    expect(member.role_access { write?(admin_access) }).to be(false)
    expect(member.role_access { write?(admin_members) }).to be(false)
    member.add_role Suma::Role.cache.admin
    expect(member.role_access { read?(admin_access) }).to be(true)
    expect(member.role_access { read?(admin_members) }).to be(true)
    expect(member.role_access { write?(admin_access) }).to be(true)
    expect(member.role_access { write?(admin_members) }).to be(true)
  end

  it "errors for invalid keys" do
    member = Suma::Fixtures.member.create
    expect do
      member.role_access { read?(:foo) }
    end.to raise_error(described_class::Invalid)
  end

  it "converts non-empty features to json" do
    member = Suma::Fixtures.member.create
    member.add_role(Suma::Role.cache.upload_files)
    expect(member.role_access.as_json).to eq({"upload_files" => ["read", "write"]})
  end
end
