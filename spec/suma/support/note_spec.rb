# frozen_string_literal: true

RSpec.describe "Suma::Support::Note", :db do
  let(:described_class) { Suma::Support::Note }

  it "is associated annotated resources" do
    member = Suma::Fixtures.member.create
    ver = Suma::Fixtures.organization_membership_verification.create

    note = Suma::Support::Note.create(content: "hi")
    note.add_member(member)
    ver.add_note(note)

    expect(note.members).to have_same_ids_as(member)
    expect(member.notes).to have_same_ids_as(note)

    expect(note.organization_membership_verifications).to have_same_ids_as(ver)
    expect(ver.notes).to have_same_ids_as(note)
  end

  it "renders markdown to html" do
    m = Suma::Fixtures.member.create
    note = m.add_note(content: "hello **there**")
    expect(note.content_html).to eq("hello <strong>there</strong>")
  end
end
