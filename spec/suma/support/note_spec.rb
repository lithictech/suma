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

  describe "creator/editor fields" do
    let(:admin) { Suma::Fixtures.member.create }
    let(:member) { Suma::Fixtures.member.create }

    it "sets the creator to the request admin on create" do
      note = Suma.set_request_user_and_admin(member, admin) do
        Suma::Fixtures.support_note.create
      end
      expect(note).to have_attributes(
        creator: be === admin,
        created_at: match_time(:now),
        editor: nil,
        edited_at: nil,
      )
    end

    it "sets the editor to the request editor on update" do
      t1 = 10.hours.ago
      t2 = 9.hours.ago
      t3 = 8.hours.ago
      t4 = 7.hours.ago

      note = Suma.set_request_user_and_admin(member, admin) do
        Suma::Fixtures.support_note.create(created_at: t1, content: "1")
      end

      admin2 = Suma::Fixtures.member.admin.create
      note = Suma.set_request_user_and_admin(member, admin2) do
        Timecop.freeze(t2) { note.update(content: "2") }
      end
      expect(note).to have_attributes(
        creator: be === admin,
        created_at: match_time(t1),
        editor: be === admin2,
        edited_at: match_time(t2),
      )

      admin3 = Suma::Fixtures.member.admin.create
      note = Suma.set_request_user_and_admin(member, admin3) do
        Timecop.freeze(t3) { note.update(content: "3") }
      end
      expect(note).to have_attributes(
        editor: be === admin3,
        edited_at: match_time(t3),
      )

      Timecop.freeze(t4) { note.update(content: "4") }
      expect(note).to have_attributes(
        editor: be_nil,
        edited_at: match_time(t4),
      )
    end
  end
end
