import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import useMountEffect from "../shared/react/useMountEffect";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function OrganizationMembershipForm({
  isCreate,
  resource,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
    }
    const memberId = Number(searchParams.get("memberId") || -1);
    const organizationId = Number(searchParams.get("organizationId") || -1);
    if (memberId > 0) {
      setField("member", {
        id: memberId,
        name: searchParams.get("memberLabel"),
      });
    }
    if (organizationId > 0) {
      setField("verifiedOrganization", {
        id: organizationId,
        name: searchParams.get("organizationLabel"),
      });
    }
  }, [searchParams]);
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
          value={resource.member?.name}
          disabled={!isCreate}
          required={isCreate}
          search={api.searchMembers}
          fullWidth
          style={{ flex: 1 }}
          onValueSelect={(m) => setField("member", m)}
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
          onValueSelect={(org) => setField("verifiedOrganization", org)}
        />
      </ResponsiveStack>
    </FormLayout>
  );
}
