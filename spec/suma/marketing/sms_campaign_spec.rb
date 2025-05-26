# frozen_string_literal: true

RSpec.describe "Suma::Marketing::SmsCampaign", :db do
  let(:described_class) { Suma::Marketing::SmsCampaign }

  it "can add and remove lists" do
    c = Suma::Fixtures.marketing_sms_campaign.create
    expect(c.lists).to be_empty
    l1 = Suma::Fixtures.marketing_list.create
    c.add_list(l1)
    expect(c.lists).to contain_exactly(l1)
  end

  describe "rendering" do
    it "returns the content if it does not parse correctly" do
      s = described_class.render(member: nil, content: "hi {{ name")
      expect(s).to eq("hi {{ name")
      s = described_class.render(member: nil, content: "hi {{ name }}")
      expect(s).to eq("hi ")
    end
  end

  describe "counting segments and characters" do
    it "counts GSM-7 messages correctly" do
      # Less than a single segment
      s = "abcd"
      expect(described_class.inspect_payload(s)).to include(characters: 4, segments: 1)

      # Max for a single segment
      s = "a" * 160
      expect(described_class.inspect_payload(s)).to include(characters: 160, segments: 1)

      # multi-segment means each is 153 chars
      s = "a" * 480
      expect(described_class.inspect_payload(s)).to include(characters: 480, segments: 4)
    end

    it "counts Unicode messages correctly" do
      # Less than a single segment
      s = "\u1234abc"
      expect(described_class.inspect_payload(s)).to include(characters: 4, segments: 1)

      # Max for one Unicode segment
      s = "\u1234" * 70
      expect(described_class.inspect_payload(s)).to include(characters: 70, segments: 1)

      # Multiple segments
      s = "\u1234" + ("a" * 159)
      expect(described_class.inspect_payload(s)).to include(characters: 160, segments: 3)
    end
  end

  describe "previewing" do
    it "can use a member" do
      c = Suma::Fixtures.marketing_sms_campaign.with_body("hello {{ name | default: 'there' }}", "hola {{name}}").create
      p = c.preview(Suma::Fixtures.member.create(name: "john"))
      expect(p[:en]).to eq("hello john")
      expect(p[:es]).to eq("hola john")
      p = c.preview(Suma::Fixtures.member.create(name: ""))
      expect(p[:en]).to eq("hello there")
      expect(p[:es]).to eq("hola ")
    end

    it "can use nil" do
      c = Suma::Fixtures.marketing_sms_campaign.with_body("hello {{ name | default: 'X' }}", "").create
      p = c.preview(nil)
      expect(p[:en]).to eq("hello X")
    end
  end

  describe "dispatching" do
    let(:campaign) { Suma::Fixtures.marketing_sms_campaign.create }

    it "dispatches a campaign to members of a list" do
      list = Suma::Fixtures.marketing_list.create
      member = Suma::Fixtures.member.create
      list.add_member(member)
      campaign.add_list(list)
      expect(Suma::Async::MarketingSmsCampaignDispatch).to receive(:perform_async)
      campaign.dispatch
      expect(campaign).to be_sent
      expect(campaign.sms_dispatches).to contain_exactly(
        have_attributes(member: be === member, sent_at: nil),
      )
    end

    it "does not duplicate members on multiple lists", :async do
      member1 = Suma::Fixtures.member.create
      member2 = Suma::Fixtures.member.create
      list1 = Suma::Fixtures.marketing_list.members(member1).create
      list2 = Suma::Fixtures.marketing_list.members(member1, member2).create
      campaign.add_list(list1)
      campaign.add_list(list2)
      campaign.sms_dispatches # Cache this to make sure we clear it after dispatch
      # Ensure we do an upsert on the dispatches, not just getting unique members.
      Suma::Fixtures.marketing_sms_dispatch.create(sms_campaign: campaign, member: member2)
      expect(Suma::Async::MarketingSmsCampaignDispatch).to receive(:perform_async)
      campaign.dispatch
      expect(campaign.sms_dispatches).to contain_exactly(
        have_attributes(member: be === member1),
        have_attributes(member: be === member2),
      )
    end
  end
end
