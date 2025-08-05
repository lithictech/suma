# frozen_string_literal: true

require_relative "behaviors"

RSpec.describe "Suma::Payment::FakeStrategy", :db do
  let(:described_class) { Suma::Payment::FakeStrategy }

  it "has associations to payouts and funding transactions" do
    ps = Suma::Fixtures.payout_transaction.with_fake_strategy.create
    expect(ps.strategy).to be_a(described_class)
    expect(ps.strategy.payout_transaction).to be === ps

    fs = Suma::Fixtures.funding_transaction.with_fake_strategy.create
    expect(fs.strategy).to be_a(described_class)
    expect(fs.strategy.funding_transaction).to be === fs
  end

  it_behaves_like "a funding transaction payment strategy" do
    let(:strategy) { xaction.strategy }
    let(:xaction) { Suma::Fixtures.funding_transaction.with_fake_strategy.create }

    it "ignores webmock errors" do
      run_error_test { Suma::Http.get("/fakeurl", logger: nil, timeout: nil) }
    end
  end

  it_behaves_like "a payout transaction payment strategy" do
    let(:strategy) { xaction.strategy }
    let(:xaction) { Suma::Fixtures.payout_transaction.with_fake_strategy.create }

    it "ignores webmock errors" do
      run_error_test { Suma::Http.get("/fakeurl", logger: nil, timeout: nil) }
    end
  end

  describe "admin_detail_typed" do
    it "returns typing info for values" do
      s = described_class.new
      details = {"Num" => 1, "T" => Time.at(0), "H" => {}, "A" => [], "Str" => "str", "Link" => "https://x.y"}
      s.set_response(:admin_details, details)
      expect(s.admin_details_typed).to eq(
        [
          {label: "Type", type: :string, value: "Fake"},
          {label: "A", type: :json, value: []},
          {label: "H", type: :json, value: {}},
          {label: "Link", type: :href, value: "https://x.y"},
          {label: "Num", type: :numeric, value: 1},
          {label: "Str", type: :string, value: "str"},
          {label: "T", type: :date, value: Time.at(0)},
        ],
      )
    end

    it "can represent models with admin_label, name, or nothing" do
      s = described_class.new
      member = Suma::Fixtures.member.create
      card = Suma::Fixtures.card.create
      session = Suma::Fixtures.session.create
      details = {
        "Searched" => member,
        "Lbl" => card,
        "Nada" => session,
      }
      s.set_response(:admin_details, details)
      expect(s.admin_details_typed).to eq(
        [
          {label: "Type", type: :string, value: "Fake"},
          {label: "Lbl", type: :model, value: {label: card.admin_label, link: card.admin_link}},
          {label: "Nada", type: :model, value: {label: "Suma::Member::Session[#{session.id}]", link: nil}},
          {label: "Searched", type: :model, value: {label: member.search_label, link: member.admin_link}},
        ],
      )
    end
  end
end
