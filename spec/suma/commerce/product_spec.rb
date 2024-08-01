# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Product", :db do
  let(:described_class) { Suma::Commerce::Product }

  describe "images" do
    it "orders images by ordinal" do
      p = Suma::Fixtures.product.create
      i1 = Suma::Fixtures.image.for(p).create(ordinal: 1)
      i3 = Suma::Fixtures.image.for(p).create(ordinal: 3)
      i2 = Suma::Fixtures.image.for(p).create(ordinal: 2)
      expect(p.refresh.images).to have_same_ids_as(i1, i2, i3)
    end
  end

  describe "images?" do
    it "returns the 'unavailable' image if there are none" do
      p = Suma::Fixtures.product.create
      expect(p.images).to be_empty
      expect(p.images?).to contain_exactly(
        have_attributes(ordinal: 0.0, uploaded_file: have_attributes(opaque_id: "missing")),
      )
    end
  end
end
