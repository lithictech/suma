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

    eligibility_constraints = [
      Suma::Fixtures.eligibility_constraint.create(name: "Homes, Oregon"),
      Suma::Fixtures.eligibility_constraint.create(name: "Casa, Oregon"),
    ]
    eligibility_constraints.each do |constraint|
      allfields.add_verified_eligibility_constraint(constraint)
    end

    plain = Suma::Fixtures.member.create(name: "XYZ", phone: "12223339999", email: "x@y.z", soft_deleted_at: Time.at(5))

    csv = described_class.new(Suma::Member.dataset).to_csv
    lines = <<~LINES
      Id,Name,Lang,Channel,Event,Phone,IntlPhone,Email,Address1,Address2,City,State,Zip,Country,Verified,Eligibility Constraints,Deleted,Timezone
      #{allfields.id},ABC,en,chan,ev,(222) 333-4444,12223334444,a@b.c,123 Main,"",Portland,Oregon,97214,US,true,"Homes, Oregon | Casa, Oregon",false,America/Los_Angeles
      #{plain.id},XYZ,,,,(222) 333-9999,12223339999,x@y.z,,,,,,,false,"",true,America/Los_Angeles
    LINES
    expect(csv).to eq(lines)
  end
end
