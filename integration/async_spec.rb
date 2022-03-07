# frozen_string_literal: true

require "rspec/eventually"

require "suma/async"
require "suma/messages/specs"

RSpec.describe "async workers", :integration do
  it "can process message deliveries" do
    c = Suma::Fixtures.customer.create
    c.soft_delete
    md = with_async_publisher do
      Suma::Messages::Testers::Basic.new.dispatch(c)
    end
    expect { md.refresh }.to eventually(have_attributes(aborted_at: be_present)).within(20)
  end
end
