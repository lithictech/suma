# frozen_string_literal: true

require "suma/postgres"
require "suma/member"

class Suma::Member::Referral < Suma::Postgres::Model(:member_referrals)
  plugin :timestamps

  many_to_one :member, class: Suma::Member
end
