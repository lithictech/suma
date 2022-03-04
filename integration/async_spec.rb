# frozen_string_literal: true

require "rspec/eventually"

require "suma/async"

RSpec.describe "async workers", :integration do
  it "registers a credit account in Increase" do
    c = Suma::Fixtures.customer.create
    c.soft_delete
    md = with_async_publisher do
      Suma::Fixtures.message_delivery.to(c).create
    end

    expect { md.refresh }.to eventually(have_attributes(aborted_at: be_present))
  end
end
