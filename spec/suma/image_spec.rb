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
      im = Suma::Fixtures.image.create(uploaded_file: Suma::Fixtures.uploaded_file.uploaded_1x1_png.create)
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
    [:program, Suma::Fixtures.program],
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

  describe "validations" do
    let(:image_uf) { Suma::Fixtures.uploaded_file.uploaded_1x1_png.create }
    let(:nonimage_uf) { Suma::Fixtures.uploaded_file.uploaded_bytes("xyz", "image/png", validate: false).create }

    it "validates the uploaded file blob is an image on create" do
      expect { Suma::Fixtures.image.create(uploaded_file: image_uf) }.to_not raise_error
      expect do
        Suma::Fixtures.image.create(uploaded_file: nonimage_uf)
      end.to raise_error(Sequel::ValidationFailed, /uploaded_file is not an image/)

      im = Suma::Fixtures.image.instance(vendor: Suma::Fixtures.vendor.create)
      im.values[:uploaded_file_id] = nonimage_uf.id
      expect { im.save_changes }.to raise_error(Sequel::ValidationFailed, /uploaded_file is not an image/)
    end

    it "validates the uploaded file blob is an image if uploaded_file_id is changed" do
      img = Suma::Fixtures.image.create(uploaded_file: image_uf)
      img_uf2 = Suma::Fixtures.uploaded_file.uploaded_1x1_png.create

      expect do
        img.update(uploaded_file: nonimage_uf)
      end.to raise_error(Sequel::ValidationFailed, /uploaded_file is not an image/)
      expect { img.update(uploaded_file: img_uf2) }.to_not raise_error
    end

    it "does not try to read the blob if the uploaded_file_id has not changed",
       reset_configuration: Suma::UploadedFile do
      img = Suma::Fixtures.image.create
      img.refresh
      Suma::UploadedFile.blob_dataset.where(sha256: img.uploaded_file.sha256).delete
      expect { img.update(ordinal: 10) }.to_not raise_error
    end

    it "can validate a private uploaded file without leaving it unlocked" do
      img2 = Suma::Fixtures.uploaded_file.uploaded_1x1_png.private.create
      img2.refresh
      img = Suma::Fixtures.image.create(uploaded_file: img2)
      img.refresh
      expect { img.update(ordinal: 10) }.to_not raise_error
    end

    it "requires an uploaded file" do
      img = Suma::Fixtures.image.instance
      img.uploaded_file = nil
      expect { img.save_changes }.to raise_error(Sequel::ValidationFailed, /uploaded_file_id is not present/)
    end
  end
end
