# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "a hybrid searchable object" do
  let(:instance) { raise "must be defined in block" }

  it "returns search document text" do
    t = instance.hybrid_search_text
    expect(t).to be_present
  end

  it "can bulk reindex", hybrid_search: true do
    t = instance
    expect(t).to have_attributes(search_content: nil)
    instance.class.hybrid_search_reindex_all
    expect(t.refresh).to have_attributes(search_content: be_present)
  end
end

RSpec.shared_examples "has a timestamp predicate" do |tsattr, boolattr|
  let(:instance) { raise "must be defined in block" }

  it "adheres to MethodUtilities.timestamp_set" do
    m = instance
    m.send(:"#{boolattr}=", false)
    expect(m.send(tsattr)).to be_nil
    expect(m.send(:"#{boolattr}?")).to be(false)

    m.send(:"#{boolattr}=", true)
    expect(m.send(tsattr)).to match_time(:now)
    expect(m.send(:"#{boolattr}?")).to be(true)

    t = 4.hours.ago
    m.send(:"#{boolattr}=", t)
    expect(m.send(tsattr)).to match_time(t)
  end
end

RSpec.shared_examples "a type with a single image" do
  let(:instance) { raise "must be defined in block" }

  it_behaves_like "a type with multiple images" do
    let(:instance) { super() }
  end

  it "has an accessor" do
    expect { instance.image }.to_not raise_error
  end
end

RSpec.shared_examples "a type with multiple images" do
  let(:instance) { raise "must be defined in block" }

  it "has an accessor" do
    expect(instance.images).to be_a(Array)
  end
end

RSpec.shared_examples "an audit log" do |audit_cls, association|
  let(:parent) { raise "must be defined in block" }

  it "has an associated object" do
    log = audit_cls.new(
      association => parent,
      at: Time.now,
      event: "test",
      to_state: "x",
      from_state: "y",
    )
    log.machine_name = "test" if log.respond_to?(:machine_name)
    log.save_changes
    expect(log.send(association)).to be === parent
  end
end
