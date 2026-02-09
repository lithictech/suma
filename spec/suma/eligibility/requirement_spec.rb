# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Requirement", :db do
  let(:described_class) { Suma::Eligibility::Requirement }

  it "can be fixtured" do
    r = Suma::Fixtures.eligibility_requirement.create
    expect(r).to be_a(described_class)
  end

  it "can get and set its resource" do
    req = Suma::Fixtures.eligibility_requirement.create
    pr = Suma::Fixtures.program.create
    pt = Suma::Fixtures.payment_trigger.create
    req.resource = pr
    expect(req).to have_attributes(program: be === pr, payment_trigger: be_nil, resource: be === pr)
    req.resource = pt
    expect(req).to have_attributes(program: be_nil, payment_trigger: be === pt, resource: be === pt)
    req.resource = nil
    expect(req).to have_attributes(program: be_nil, payment_trigger: be_nil, resource: be_nil)
    expect { req.resource = 5 }.to raise_error(TypeError, /invalid association type: Integer\(5\)/)
  end
end
