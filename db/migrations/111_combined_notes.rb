# frozen_string_literal: true

Sequel.migration do
  up do
    create_view :support_notes_combined_view,
                from(:support_notes).
                  left_join(:support_notes_members, {note_id: :id}).
                  select(
                    Sequel[:support_notes].*,
                    :member_id,
                    Sequel[nil].as(:verification_id),
                  ).
                  union(
                    from(:support_notes).
                      left_join(:support_notes_organization_membership_verifications, {note_id: :id}).
                      left_join(:organization_membership_verifications, {id: :verification_id}).
                      left_join(:organization_memberships, {id: :membership_id}).
                      select(
                        Sequel[:support_notes].*,
                        :member_id,
                        :verification_id,
                      ),
                  ).order(Sequel.desc(Sequel.function(:coalesce, :edited_at, :created_at)), :id)
  end
  down do
    drop_view :support_notes_combined_view
  end
end
