# frozen_string_literal: true

RSpec.describe "Suma::Commerce::Product", :db do
  let(:described_class) { Suma::Commerce::Product }

  describe "images" do
    it "orders images by ordinal" do
      p = Suma::Fixtures.commerce_product.create
      i1 = p.add_image({uploaded_file: Suma::Fixtures.uploaded_file.create, ordinal: 1})
      i3 = p.add_image({uploaded_file: Suma::Fixtures.uploaded_file.create, ordinal: 3})
      i2 = p.add_image({uploaded_file: Suma::Fixtures.uploaded_file.create, ordinal: 2})
      expect(p.refresh.images).to have_same_ids_as(i1, i2, i3)
    end
  end

  describe "images?" do
    it "returns the 'unavailable' image if there are none" do
      p = Suma::Fixtures.commerce_product.create
      expect(p.images).to be_empty
      expect(p.images?).to contain_exactly(
        have_attributes(ordinal: 0.0, uploaded_file: have_attributes(opaque_id: "missing")),
      )
    end
  end
end
