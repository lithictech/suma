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

  describe "caching" do
    it "denormalizes and caches expression info on save" do
      attr = Suma::Fixtures.eligibility_attribute.create(name: "foo")
      req = Suma::Fixtures.eligibility_requirement.create
      expect(req).to have_attributes(cached_attribute_ids: [], cached_expression_string: "")
      req.expression.update(attribute: attr)
      req.update(search_content: "bar")
      expect(req).to have_attributes(cached_attribute_ids: [attr.id], cached_expression_string: "'foo'")
    end

    it "does not load expression info if not loaded" do
      req = Suma::Fixtures.eligibility_requirement.create
      # Update the database directly
      req.this.update(cached_expression_string: "foo")
      req.refresh # Remove loaded expression
      expect(req.associations[:expression]).to be_nil
      # Update some field, make sure expression wasn't regenerated
      req.update(search_content: "bar")
      req.refresh
      expect(req).to have_attributes(cached_expression_string: "foo")
      # Load the association so we'll regenerate the cached values
      req.expression
      req.update(search_content: "bar")
      expect(req).to have_attributes(cached_expression_string: "")
      req.refresh
      expect(req).to have_attributes(cached_expression_string: "")
    end
  end
end
