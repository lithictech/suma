# frozen_string_literal: true

require "suma/postgres"
require "suma/member"

class Suma::Member::Referral < Suma::Postgres::Model(:member_referral)
  plugin :timestamps

  one_to_one :member, class: Suma::Member
end
