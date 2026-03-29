# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Requirement", :db do
  let(:described_class) { Suma::Eligibility::Requirement }

  it "can be fixtured" do
    r = Suma::Fixtures.eligibility_requirement.create
    expect(r).to be_a(described_class)
  end

  it "creates and associates an expression automatically" do
    req = Suma::Fixtures.eligibility_requirement.create
    expect(req.expression).to be_a(Suma::Eligibility::Expression)
    expect(req.expression.requirement).to be === req
  end

  it "has an association to resources" do
    req = Suma::Fixtures.eligibility_requirement.create
    pr = Suma::Fixtures.program.create
    pt = Suma::Fixtures.payment_trigger.create
    req.add_program(pr)
    req.add_payment_trigger(pt)
    expect(req.programs).to contain_exactly(be === pr)
    expect(req.payment_triggers).to contain_exactly(be === pt)
    expect(pr.eligibility_requirements).to contain_exactly(be === req)
    expect(pt.eligibility_requirements).to contain_exactly(be === req)
  end

  describe "caching" do
    it "denormalizes and caches expression info on save" do
      attr = Suma::Fixtures.eligibility_attribute.create(name: "foo")
      req = Suma::Fixtures.eligibility_requirement.create
      expect(req).to have_attributes(cached_attribute_ids: [], cached_expression_string: "")
      req.expression.update(type: "attribute", attribute: attr, operator: nil)
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

  describe "replace_expression" do
    it "updates the expression" do
      req = Suma::Fixtures.eligibility_requirement.create
      expect(req.expression.serialize).to eq({op: "AND"})
      old = req.expression
      req.replace_expression({op: "OR"})
      expect(req.expression).to_not be === old
      expect(req.expression.serialize).to eq({op: "OR"})
    end

    it "noops if the expression has not changed" do
      req = Suma::Fixtures.eligibility_requirement.create
      expect(req.expression.serialize).to eq({op: "AND"})
      old = req.expression
      req.replace_expression({op: "AND"})
      expect(req.expression).to be === old
    end
  end
end
