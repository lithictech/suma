# frozen_string_literal: true

require "geokit"

RSpec.describe "Suma::Address", :db do
  let(:described_class) { Suma::Address }

  let(:geoloc) { Suma::Fixtures.geolocation }

  it "can be limited to instances that are geocoded in the US" do
    us_geoloc = geoloc.successful.instance
    us_address = Suma::Fixtures.address.create(geocoder_data: us_geoloc)

    ca_address = Faker::Address.with_locale("en-CA") do
      ca_geoloc = geoloc.successful.instance(country_code: "ca")
      Suma::Fixtures.address.create(country: "ca", geocoder_data: ca_geoloc).save_changes
    end

    expect(described_class.geocoded_in_the_us.all).to contain_exactly(us_address)
  end

  it "has a dataset for addresses that failed geocoding" do
    never_geocoded = Suma::Fixtures.address.create
    failed_geocoded = Suma::Fixtures.address.create(
      geocoder_data: geoloc.failed.instance,
    )
    successfully_geocoded = Suma::Fixtures.address.with_geocoding_data.create

    expect(described_class.failed_geocoding).to contain_exactly(failed_geocoded)
  end

  it "provides aliases for getting and setting state or province by the short name" do
    address = described_class.new(state_or_province: "DC")
    expect(address.state).to eq("DC")
    address.state = "NY"
    expect(address.state).to eq("NY")
  end

  it "returns both of its address lines if both are set" do
    address = described_class.new(
      address1: "524 E. Burnside",
      address2: "Suite 410",
      city: "Portland",
      state_or_province: "OR",
      postal_code: "97214",
      country: "US",
    )
    expect(address.address_lines).to eq(["524 E. Burnside", "Suite 410"])
  end

  it "does not include the unset address line if one is unset" do
    address = described_class.new(
      address1: "101 Independence Ave SE",
      address2: "",
      city: "Washington",
      state_or_province: "DC",
      postal_code: "20540",
      country: "US",
    )
    expect(address.address_lines).to eq(["101 Independence Ave SE"])
  end

  it "does not include address2 in its geocodable address" do
    address = described_class.new(
      address1: "524 E. Burnside",
      address2: "Suite 410",
      city: "Portland",
      state_or_province: "OR",
      postal_code: "97214",
      country: "US",
    )
    expect(address.geocodable_address).to_not include("Suite 410")
  end

  it "can be told to not return the country in its one line address" do
    address = described_class.new(
      address1: "524 E. Burnside",
      address2: "Suite 410",
      city: "Portland",
      state_or_province: "OR",
      postal_code: "97214",
      country: "US",
    )
    expect(address.one_line_address(include_country: false)).to_not include("US")
  end

  it "includes blank items in its one line address" do
    address = described_class.new(
      address1: "524 E. Burnside",
      address2: "",
      city: "Portland",
      state_or_province: "OR",
      postal_code: "",
      country: "US",
    )
    expect(address.one_line_address).to eq("524 E. Burnside, Portland, OR, US")
  end

  it "can create a new instance via a geocoder" do
    expect(described_class.geocoder).to receive(:geocode).
      with("1619 Pine Street, boulder, co", bias: "us").
      and_return(geoloc.mork_and_mindys_house.instance)

    addr = described_class.parse_address_string("1619 Pine Street, boulder, co")

    expect(addr.address1).to eq("1619 Pine Street")
    expect(addr.city).to eq("Boulder")
    expect(addr.state).to eq("CO")
    expect(addr.zip).to eq("80302")
  end

  it "can geocode itself into its geocoder_data field" do
    address = Suma::Fixtures.address.create
    geolocation = geoloc.from_address(address).instance

    expect(described_class.geocoder).to receive(:geocode).
      with(address.geocodable_address, bias: "US").
      and_return(geolocation)

    address.geocode

    address.refresh
    expect(address.geocoder_data["street_address"]).to eq(Geokit::Inflector.titleize(address.address1))
    expect(address.geocoder_data["city"]).to eq(Geokit::Inflector.titleize(address.city))
    expect(address.geocoder_data["state"]).to eq(address.state)
    expect(address.geocoder_data["zip"]).to eq(address.zip)
    expect(address.geocoder_data["lat"]).to eq(address.lat)
    expect(address.geocoder_data["lng"]).to eq(address.lng)
    expect(geolocation.suggested_bounds.to_a).to eq(address.suggested_bounds_nesw)
  end

  it "can geocode itself from failed geocoding" do
    address = Suma::Fixtures.address.create
    expect(described_class.geocoder).to receive(:geocode).
      with(address.geocodable_address, bias: "US").
      and_return(geoloc.failed.instance)

    address.geocode

    expect(address.lat).to be_nil
    expect(address.lng).to be_nil
    expect(address.suggested_bounds_nesw).to be_empty
  end

  it "does not re-geocode itself if its geocodeable address has not changed" do
    expect(described_class.geocoder).to receive(:geocode).once.and_return(geoloc.successful.instance)

    address = Suma::Fixtures.address.with_geocoding_data.create
    address.geocode
    address.geocode
  end

  it "will geocode itself if latitude is nil" do
    expect(described_class.geocoder).to receive(:geocode).once.and_return(geoloc.successful.instance)

    address = Suma::Fixtures.address.with_geocoding_data.create
    address.geocode
    address.geocode
  end

  it "can force re-geocoding with geocode!" do
    expect(described_class.geocoder).to receive(:geocode).twice.and_return(geoloc.successful.instance)

    address = Suma::Fixtures.address.with_geocoding_data.create
    address.geocode
    address.geocode!
  end

  it "errors if address1 is blank" do
    expect do
      Suma::Fixtures.address(address1: "").create.geocode
    end.to raise_error(/address1 cannot be blank/)
  end

  it "can encode its street view url" do
    url = Suma::Fixtures.address(city: "Allen Town").create.street_view_url
    expect(url).to include("https://maps.googleapis.com")
    expect(url).to include("Allen+Town")
  end

  describe "looking up by fields" do
    let(:fields) do
      {
        address1: Faker::Address.street_address,
        city: Faker::Address.city,
        state_or_province: Faker::Address.state,
        postal_code: Faker::Address.zip,
      }
    end

    it "creates and returns an address if none found matching fields" do
      address = described_class.lookup(fields)

      expect(address).to be_saved
      expect(address.address1).to eq(fields[:address1])
    end

    it "returns an existing address if found" do
      address = described_class.create(fields)

      expect(described_class.lookup(fields)).to be === address
    end

    it "applies changes to fields that are not part of the primary identity" do
      fields[:address1] = "1 Main"
      fields[:address2] = "Unit 2"
      fields[:state_or_province] = "NY"

      address = described_class.create(fields)

      extracted = described_class.lookup(
        address1: "1 main",
        address2: "unit 2",
        postal_code: fields[:postal_code],
        state_or_province: "OR",
      )
      expect(extracted).to be === address
      expect(extracted.changed_columns).to include(:address1, :address2, :state_or_province)
      expect(extracted.address1).to eq("1 main")
      expect(extracted.address2).to eq("unit 2")
      expect(extracted.state).to eq("OR")
    end

    it "looks up the address with only idenity fields" do
      address = described_class.create(fields)

      fields[:address1] = "foo"
      extracted = described_class.lookup(fields)
    end

    it "can initialize a lat/lng for a new address" do
      address = described_class.lookup(fields.merge(lat: 20, lng: 50))
      expect(address).to be_saved
      expect(address).to have_attributes(lat: 20, lng: 50)
    end

    it "does not modify lat/lng for an existing address" do
      address = described_class.create(fields)
      address[:lat] = 4
      address[:lng] = 7
      address.save_changes

      found = described_class.lookup(fields.merge(lat: 20, lng: 50))
      expect(found).to be === address
      expect(found).to have_attributes(lat: 4, lng: 7)
      expect(address.refresh).to have_attributes(lat: 4, lng: 7)
    end
  end

  describe "fields" do
    it "returns address data fields" do
      addr = Suma::Fixtures.address.instance
      expect(addr.fields.keys).to contain_exactly(:address1, :address2, :city, :state_or_province, :postal_code)
    end
  end
end
