import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import useMountEffect from "../shared/react/useMountEffect";
import merge from "lodash/merge";
import React from "react";

export default function OrganizationMembershipForm({
  isCreate,
  resource,
  setField,
  setFields,
  register,
  isBusy,
  onSubmit,
}) {
  // These fields are required, so always set the values to the form API
  useMountEffect(() => {
    if (resource.organization && resource.member) {
      const memberResource = { member: { id: resource.member.id } };
      const organizationResource = { organization: { id: resource.organization.id } };
      setFields(merge(memberResource, organizationResource));
    }
  }, []);
  return (
    <FormLayout
      title={
        isCreate ? "Create an Organization Membership" : "Update Organization Membership"
      }
      subtitle="Organization Memberships include the member that is eligible for
      the specific Organization such as Hacienda CDC or affordable housing partners.
      A member is allowed to have multiple organization memberships, since it is the reality."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <ResponsiveStack>
        <AutocompleteSearch
          {...register("member")}
          label="Member"
          helperText="The member elgible for this organization"
          value={resource.member?.label || resource.member?.name}
          fullWidth
          required
          search={api.searchMembers}
          style={{ flex: 1 }}
          onValueSelect={(m) => setField("member", { id: m.id })}
        />
        <AutocompleteSearch
          {...register("organization")}
          label="Organization"
          helperText="Organization that member is elgible for"
          value={resource.organization?.name}
          fullWidth
          required
          search={api.searchOrganizations}
          style={{ flex: 1 }}
          onValueSelect={(org) => setField("organization", { id: org.id })}
        />
      </ResponsiveStack>
    </FormLayout>
  );
}
