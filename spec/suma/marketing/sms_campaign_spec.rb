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
      expect(described_class::Payload.parse(s)).to have_attributes(characters: 4, segments: 1)

      # Max for a single segment
      s = "a" * 160
      expect(described_class::Payload.parse(s)).to have_attributes(characters: 160, segments: 1)

      # multi-segment means each is 153 chars
      s = "a" * 480
      expect(described_class::Payload.parse(s)).to have_attributes(characters: 480, segments: 4)
    end

    it "counts Unicode messages correctly" do
      # Less than a single segment
      s = "\u1234abc"
      expect(described_class::Payload.parse(s)).to have_attributes(characters: 4, segments: 1)

      # Max for one Unicode segment
      s = "\u1234" * 70
      expect(described_class::Payload.parse(s)).to have_attributes(characters: 70, segments: 1)

      # Multiple segments
      s = "\u1234" + ("a" * 159)
      expect(described_class::Payload.parse(s)).to have_attributes(characters: 160, segments: 3)
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

    it "does not duplicate members on multiple lists" do
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

    it "upserts new rows if force is true" do
      member1 = Suma::Fixtures.member.create
      member2 = Suma::Fixtures.member.create
      list1 = Suma::Fixtures.marketing_list.members(member1).create
      campaign.add_list(list1)
      expect(Suma::Async::MarketingSmsCampaignDispatch).to receive(:perform_async).twice
      campaign.dispatch
      expect(campaign.sms_dispatches).to contain_exactly(
        have_attributes(member: be === member1),
      )
      campaign.refresh
      list1.add_member(member2)
      campaign.dispatch(force: true)
      expect(campaign.sms_dispatches).to contain_exactly(
        have_attributes(member: be === member1),
        have_attributes(member: be === member2),
      )
    end

    it "re-enqueues the job only if the campaign is already sent" do
      list = Suma::Fixtures.marketing_list.members(Suma::Fixtures.member.create).create
      campaign.add_list(list)
      campaign.sent = true
      expect(Suma::Async::MarketingSmsCampaignDispatch).to receive(:perform_async)
      campaign.dispatch
      expect(campaign.sms_dispatches).to be_empty
    end
  end

  describe "review" do
    it "includes all expected pre-review information" do
      list1 = Suma::Fixtures.marketing_list(label: "list1").
        members(
          Suma::Fixtures.member.with_preferences(preferred_language: "en").create,
        ).
        create
      list2 = Suma::Fixtures.marketing_list(label: "list2").
        members(
          Suma::Fixtures.member(name: "n").with_preferences(preferred_language: "es").create,
          Suma::Fixtures.member(name: "s" * 200).with_preferences(preferred_language: "en").create,
        ).
        create
      campaign = Suma::Fixtures.marketing_sms_campaign.with_body("{{ name }}", "{{ name }}").create
      campaign.add_list(list1)
      campaign.add_list(list2)
      v = campaign.generate_review
      expect(v).to have_attributes(
        campaign: be === campaign,
        en_recipients: 2,
        en_total_cost: BigDecimal("0.01245"),
        es_recipients: 1,
        es_total_cost: BigDecimal("0.00415"),
        list_labels: ["list1 (1)", "list2 (2)"],
        total_cost: BigDecimal("0.0166"),
        total_recipients: 3,
      )
    end

    it "does not expect dispatches for blank bodies" do
      list = Suma::Fixtures.marketing_list(label: "list").
        members(
          Suma::Fixtures.member.with_preferences(preferred_language: "en").create,
          Suma::Fixtures.member.with_preferences(preferred_language: "es").create,
        ).
        create
      campaign = Suma::Fixtures.marketing_sms_campaign.with_body(" ", "{{ name }}").create
      campaign.add_list(list)
      v = campaign.generate_review
      expect(v).to have_attributes(
        campaign: be === campaign,
        en_recipients: 0,
        es_recipients: 1,
        total_recipients: 1,
      )
    end

    it "includes all expected post-review information" do
      list1 = Suma::Fixtures.marketing_list(label: "list1").create
      campaign = Suma::Fixtures.marketing_sms_campaign.create(sent_at: Time.now)
      campaign.add_list(list1)
      v = campaign.generate_review
      expect(v).to have_attributes(
        campaign: be === campaign,
        list_labels: ["list1"],
        total_recipients: 0,
        delivered_recipients: 0,
        failed_recipients: 0,
        pending_recipients: 0,
        actual_cost: BigDecimal("0.00"),
      )

      dispatch_fac = Suma::Fixtures.marketing_sms_dispatch(sms_campaign: campaign)
      sent1 = dispatch_fac.sent("sw1").create
      sent2 = dispatch_fac.sent("sw2").create
      pending1 = dispatch_fac.sent("sw3").create
      failed1 = dispatch_fac.sent("sw4").create
      unsent1 = dispatch_fac.create
      canceled = dispatch_fac.canceled.create
      Suma::Webhookdb.signalwire_messages_dataset.insert(sw_row("sw1", "delivered", 0.001))
      Suma::Webhookdb.signalwire_messages_dataset.insert(sw_row("sw2", "sent", 0.001))
      Suma::Webhookdb.signalwire_messages_dataset.insert(sw_row("sw3", "queued", 0.001))
      Suma::Webhookdb.signalwire_messages_dataset.insert(sw_row("sw4", "undelivered", 0.001))

      v = campaign.generate_review
      expect(v).to have_attributes(
        total_recipients: 6,
        delivered_recipients: 2,
        failed_recipients: 1,
        pending_recipients: 2,
        canceled_recipients: 1,
        actual_cost: BigDecimal("0.004"),
      )
    end

    def sw_row(sid, status, price)
      r = {
        signalwire_id: sid,
        data: {sid:, status:, price:}.to_json,
      }
      return r
    end
  end
end
