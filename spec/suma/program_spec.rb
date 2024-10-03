# frozen_string_literal: true

RSpec.describe "Suma::Program", :db do
  let(:described_class) { Suma::Program }

  describe "datasets" do
    describe "active" do
      it "includes rows were now is within the period" do
        Suma::Fixtures.program.expired.create
        Suma::Fixtures.program.future.create
        active = Suma::Fixtures.program.create
        expect(described_class.active.all).to have_same_ids_as(active)
      end
    end
  end

  it "can associate with an image" do
    p = Suma::Fixtures.program.with_image.create
    expect(p.images).to have_length(1)
  end
end
