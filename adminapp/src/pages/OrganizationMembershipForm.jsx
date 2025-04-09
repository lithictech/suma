import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import useMountEffect from "../shared/react/useMountEffect";
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Radio,
  RadioGroup,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function OrganizationMembershipForm({
  isCreate,
  resource,
  setField,
  setFieldFromInput,
  clearField,
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  const origMembershipType = resource.membershipType;
  const [membershipType, setMembershipType] = React.useState(origMembershipType);

  const membershipTypes = [];
  if (isCreate || resource.unverifiedOrganizationName) {
    // We can create an unverified or verified membership,
    // or modify an unverified into a verified.
    membershipTypes.push({ label: "Unverified", value: "unverified" });
    membershipTypes.push({ label: "Verified", value: "verified" });
  } else if (resource.verifiedOrganization) {
    // We can remove a verified membership.
    membershipTypes.push({ label: "Verified", value: "verified" });
    membershipTypes.push({ label: "Removed", value: "removed" });
  } else {
    // We cannot edit a removed membership.
    membershipTypes.push({ label: "Removed", value: "removed" });
  }

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

  const handleTypeChange = React.useCallback(
    (e) => {
      const mt = e.target.value;
      setMembershipType(mt);
      if (mt === "unverified") {
        // If we're choosing unverified, it can only be because we are currently unverified,
        // and may have chosen a verified org. If we did, remove the verified org.
        clearField("verifiedOrganization");
      } else if (mt === "verified") {
        // If we're choosing verified, it could be because we're unverified->verified
        // (so clear out any name change), or toggling back from 'removed'
        // (so clear out the flag).
        clearField("unverifiedOrganizationName");
        clearField("removeFromOrganization");
      } else if (mt === "removed") {
        // If we're choosing removed, it can only be because we toggled to it from verified.
        // The org is already immutable; so just set the flag to remove the member.
        setField("removeFromOrganization", true);
      }
    },
    [setField, clearField]
  );

  return (
    <FormLayout
      title={
        isCreate ? "Create an Organization Membership" : "Update Organization Membership"
      }
      subtitle="Organization memberships associate a member and a platform partner, such as an affordable housing provider or government entity."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <Typography>The member who is in an organization:</Typography>
        <AutocompleteSearch
          {...register("member")}
          label="Member"
          value={resource.member?.name}
          disabled={!isCreate}
          required={isCreate}
          search={api.searchMembers}
          fullWidth
          style={{ flex: 1 }}
          onValueSelect={(m) => setField("member", m)}
        />
        {membershipTypes.length > 0 && (
          <FormControl disabled={membershipTypes.length === 1}>
            <FormLabel>Membership Type</FormLabel>
            <RadioGroup value={membershipType} row onChange={handleTypeChange}>
              {membershipTypes.map(({ label, value }) => (
                <FormControlLabel
                  key={value}
                  value={value}
                  control={<Radio />}
                  label={label}
                />
              ))}
            </RadioGroup>
          </FormControl>
        )}
        {membershipType === "unverified" && (
          <TextField
            {...register("unverifiedOrganizationName")}
            label="Organization Name"
            name="unverifiedOrganizationName"
            value={resource.unverifiedOrganizationName}
            fullWidth
            onChange={setFieldFromInput}
          />
        )}
        {membershipType === "verified" && (
          <>
            <Typography>
              The organization the member is a part of.
              {resource.unverifiedOrganizationName && (
                <span>
                  {" "}
                  The member has identified themselves with:
                  <br />
                  <strong>{resource.unverifiedOrganizationName}</strong>.
                </span>
              )}
            </Typography>
            <AutocompleteSearch
              {...register("verifiedOrganization")}
              label="Organization"
              value={resource.verifiedOrganization?.name}
              fullWidth
              required
              disabled={origMembershipType === "verified"}
              search={api.searchOrganizations}
              style={{ flex: 1 }}
              onValueSelect={(org) => setField("verifiedOrganization", org)}
            />
          </>
        )}
        {origMembershipType === "removed" && (
          <>
            <Typography>
              This member has already been removed from the following organization. Create
              a new membership to re-add them.
            </Typography>
            <TextField disabled value={resource.formerOrganization.name} />
          </>
        )}
      </Stack>
    </FormLayout>
  );
}
