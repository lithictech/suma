# frozen_string_literal: true

require "suma/api/support"

RSpec.describe Suma::API::Support, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  describe "POST /v1/support/regain_account_access" do
    let(:previous_phone) { "15551112222" }
    let(:current_phone) { "15551113333" }

    it "creates a support ticket" do
      post "/v1/support/regain_account_access", previous_phone:, current_phone:, name: " Rob "

      expect(last_response).to have_status(204)
      expect(Suma::Support::Ticket.all).to contain_exactly(
        have_attributes(
          sender_name: "Rob",
          body: "Name: Rob\nPrevious Phone: (555) 111-2222\nCurrent Phone: (555) 111-3333",
        ),
      )
    end

    it "includes previous/current links of matching members" do
      prev = Suma::Fixtures.member.create(phone: previous_phone)
      curr = Suma::Fixtures.member.create(phone: current_phone)

      post "/v1/support/regain_account_access", previous_phone:, current_phone:, name: " Rob "

      expect(last_response).to have_status(204)
      expect(Suma::Support::Ticket.all).to contain_exactly(
        have_attributes(
          body: "Name: Rob\nPrevious Phone: (555) 111-2222\nCurrent Phone: (555) 111-3333\n" \
                "Previous Member: http://localhost:22014/member/#{prev.id}\n" \
                "Current Member: http://localhost:22014/member/#{curr.id}",
        ),
      )
    end
  end
end
