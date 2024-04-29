import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import React from "react";

export default function OrganizationMembershipForm({
  isCreate,
  resource,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
  let orgText = "The organization the member is a part of.";
  if (resource.unverifiedOrganizationName) {
    orgText += ` The member has identified themselves with '${resource.unverifiedOrganizationName}.'`;
  }
  return (
    <FormLayout
      title={
        isCreate ? "Create an Organization Membership" : "Update Organization Membership"
      }
      subtitle="Organization memberships associate a member and a platform partner, such as an affordable housing provider or government entity."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <ResponsiveStack>
        <AutocompleteSearch
          {...register("member")}
          label="Member"
          helperText="The member who is in an organization."
          value={resource.member?.label || resource.member?.name}
          disabled={!isCreate}
          required={isCreate}
          search={api.searchMembers}
          fullWidth
          style={{ flex: 1 }}
          onValueSelect={(m) => setField("member", { id: m.id })}
        />
        <AutocompleteSearch
          {...register("organization")}
          label="Organization"
          helperText={orgText}
          value={resource.verifiedOrganization?.name}
          fullWidth
          required
          search={api.searchOrganizations}
          style={{ flex: 1 }}
          onValueSelect={(org) => setField("verifiedOrganization", { id: org.id })}
        />
      </ResponsiveStack>
    </FormLayout>
  );
}
