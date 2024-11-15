# frozen_string_literal: true

RSpec.describe Suma::Member::Exporter, :db do
  it "exports to csv" do
    allfields = Suma::Fixtures.member.create(
      name: "ABC", phone: "12223334444", email: "a@b.c", onboarding_verified_at: Time.now,
    )
    Suma::Fixtures.referral.create(member: allfields, event_name: "ev", channel: "chan")
    address = Suma::Fixtures.address.create(
      address1: "123 Main", address2: "", city: "Portland", state_or_province: "Oregon", postal_code: "97214",
    )
    allfields.legal_entity.update(address:)
    allfields.message_preferences!

    enrollment_fac = Suma::Fixtures.program_enrollment(member: allfields)
    enrollment_fac.create(program: Suma::Fixtures.program.named("Homes, Oregon").create)
    enrollment_fac.create(program: Suma::Fixtures.program.named("Casa, Oregon").create)

    plain = Suma::Fixtures.member.create(name: "XYZ", phone: "12223339999", email: "x@y.z")
    plain.soft_delete

    csv = described_class.new(Suma::Member.dataset).to_csv
    lines = <<~LINES
      Id,Name,Lang,Channel,Event,Phone,IntlPhone,Email,Address1,Address2,City,State,Zip,Country,Verified,Programs,Deleted,Timezone
      #{allfields.id},ABC,en,chan,ev,(222) 333-4444,12223334444,a@b.c,123 Main,"",Portland,Oregon,97214,US,true,"Casa, Oregon|Homes, Oregon",false,America/Los_Angeles
      #{plain.id},XYZ,,,,#{plain.phone},#{plain.phone},#{plain.email},,,,,,,false,"",true,America/Los_Angeles
    LINES
    expect(csv).to eq(lines)
  end

  it "adds UNSAFE before values that start with an equal sign to avoid exporing a macro" do
    member1 = Suma::Fixtures.member.create(name: "=1+1")
    member2 = Suma::Fixtures.member.create(name: "==1+1")
    member3 = Suma::Fixtures.member.create(name: " =1+1")
    member4 = Suma::Fixtures.member.create(name: "  =1+1")
    member5 = Suma::Fixtures.member.create(name: "\t=1+1")
    csv = described_class.new(Suma::Member.dataset).to_csv
    expect(csv).to include("#{member1.id},UNSAFE=1+1")
    expect(csv).to include("#{member2.id},UNSAFE==1+1")
    expect(csv).to include("#{member3.id},UNSAFE =1+1")
    expect(csv).to include("#{member4.id},UNSAFE  =1+1")
    expect(csv).to include("#{member5.id},UNSAFE\t=1+1")
  end
end
