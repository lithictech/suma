# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/release"

RSpec.describe Suma::Tasks::Release, :db do
  include Suma::SpecHelpers::Rake

  describe "release" do
    it "migrates the database, marks the Sidekiq deployment, imports static strings" do
      Sidekiq.redis(&:flushdb)
      stub_const("Suma::RELEASE", "fakerelease")
      marks = Timecop.freeze("2025-02-15T12:00:00Z") do
        invoke_rake_task("release")
        Sidekiq::Deploy.new.fetch
      end
      expect(marks).to eq({"2025-02-15T12:00:00Z" => "fakerelease"})
      expect(Suma::I18n::StaticString.dataset).to_not be_empty
    end
  end

  describe "prepare_prod_db_for_testing", db: :no_transaction do
    it "cleans passwords, stripe json, and un-deletes superadmin" do
      m = Suma::Fixtures.member.create(password: SecureRandom.hex(20), stripe_customer_json: "{}")
      expect(m.authenticate?("suma1234")).to be(false)
      admin = Suma::Fixtures.member.create(email: "admin@lithic.tech", soft_deleted_at: Time.now)
      invoke_rake_task("release:prepare_prod_db_for_testing")
      expect(m.refresh.authenticate?("Password1!")).to be(true)
      expect(m.stripe_customer_json).to be_nil
      expect(admin.refresh).to_not be_soft_deleted
    end
  end

  describe "randomize_passwords" do
    it "randomizes passwords on all members", :redirect do
      expect(SecureRandom).to receive(:hex).with(24).and_return("abcd1234")
      m = Suma::Fixtures.member.create(email: "x@y.z")
      Suma::Fixtures.member.create(email: nil)
      invoke_rake_task("release:randomize_passwords")
      expect($stdout.string).to eq("x@y.z: abcd1234\n")
      expect(m.refresh.authenticate?("abcd1234")).to be(true)
    end
  end
end
