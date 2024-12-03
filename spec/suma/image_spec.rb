# frozen_string_literal: true

RSpec.describe "Suma::Image", :db do
  let(:described_class) { Suma::Image }

  describe "AssociatedMixin" do
    describe "images" do
      it "orders images by ordinal" do
        p = Suma::Fixtures.offering.create
        i3 = Suma::Fixtures.image.for(p).create(ordinal: 3)
        i1 = Suma::Fixtures.image.for(p).create(ordinal: 1)
        i2 = Suma::Fixtures.image.for(p).create(ordinal: 2)
        expect(p.refresh.images).to have_same_ids_as(i1, i2, i3)
        expect(p.image).to be === i1
      end
    end

    describe "images?" do
      it "returns the 'unavailable' image if there are none" do
        p = Suma::Fixtures.offering.create
        expect(p.images).to be_empty
        expect(p.images?).to contain_exactly(
          have_attributes(ordinal: 0.0, uploaded_file: have_attributes(opaque_id: "missing")),
        )
        expect(p.image).to be_nil
        expect(p.image?).to have_attributes(ordinal: 0.0)
      end
    end
  end

  describe "SingleAssociatedMixin" do
    it "returns the first image of the array" do
      o = Suma::Fixtures.vendor.create
      img1 = Suma::Fixtures.image.for(o).create
      img2 = Suma::Fixtures.image.for(o).create
      expect(o.images).to have_same_ids_as(img1, img2)
      expect(o.image).to be === img1
    end

    it "replaces all images when setting" do
      o = Suma::Fixtures.vendor.create
      img1 = Suma::Fixtures.image.for(o).create
      img2 = Suma::Fixtures.image.for(o).create
      # Access this to cache the association to make sure it gets busted/set
      expect(o.images).to have_same_ids_as(img1, img2)
      im = Suma::Fixtures.image.create(uploaded_file: Suma::Fixtures.uploaded_file.create)
      o.image = im
      img3 = o.image
      expect(img3.vendor).to be === o
      expect(img3).to have_attributes(id: be > img2.id)
      expect(o.images).to have_same_ids_as(img3)
      expect(o.images).to have_same_ids_as(img3)
      expect(o.refresh.images_dataset.all).to have_same_ids_as(img3)

      # Make sure setting the same image doesn't accidentally delete it when clearing out existing ones
      o.image = img3
      expect(o.images_dataset.all).to have_same_ids_as(img3)
    end
  end

  [
    [:commerce_offering, Suma::Fixtures.offering],
    [:commerce_product, Suma::Fixtures.product],
    [:vendor, Suma::Fixtures.vendor],
    [:vendor_service, Suma::Fixtures.vendor_service],
  ].each do |(assoc, fac)|
    it "handles the #{assoc} association" do
      related = fac.create
      img = Suma::Fixtures.image.for(related).create
      expect(img.associated_object).to be(related)

      img.associated_object = nil
      img.send(:"#{assoc}=", related)
      expect(img.send(assoc)).to be(related)
      expect(img.associated_object).to be(related)
    end
  end

  it "errors for an unknown associated object" do
    img = described_class.new
    expect(img.associated_object).to be_nil
    offering = Suma::Fixtures.offering.create
    img.associated_object = offering
    expect(img.associated_object).to be === offering
    img.associated_object = nil
    expect(img.associated_object).to be_nil
    expect { img.associated_object = 5 }.to raise_error(TypeError, /invalid associated/)
  end
end
