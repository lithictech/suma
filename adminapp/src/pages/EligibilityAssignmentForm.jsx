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
} from "@mui/material";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function EligibilityAssignmentForm({
  isCreate,
  resource,
  setField,
  clearField,
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  const searchAttributeId = Number(searchParams.get("attributeId") || -1);
  const searchAssigneeId = Number(searchParams.get("assigneeId") || -1);
  const searchAssigneeType = searchParams.get("assigneeType");
  const [assigneeType, setAssigneeType] = React.useState(
    resource.assigneeType || searchAssigneeType || "member"
  );
  const fixedAssignee = searchAssigneeId > 0;
  const fixedAttribute = searchAttributeId > 0;

  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
    }
    if (searchAttributeId > 0) {
      setField("attribute", {
        id: searchAttributeId,
        label: searchParams.get("attributeLabel"),
      });
    }
    if (searchAssigneeId > 0) {
      setField(searchAssigneeType, {
        id: searchAssigneeId,
        label: searchParams.get("assigneeLabel"),
      });
    }
  }, [searchParams]);

  const handleAssigneeTypeChange = (e) => {
    setAssigneeType(e.target.value);
    clearField(assigneeType);
  };

  return (
    <FormLayout
      title={
        isCreate ? "Assign an Eligibility Attribute" : "Update an Eligbility Assignment"
      }
      subtitle="Assign eligibility attributes to members, organizations, and roles.
      Members get all the eligibility attributes assigned to them,
      roles added to them, organizations they're a member of,
      and the roles added to organizations they're a member of."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <AutocompleteSearch
          {...register("attribute")}
          label="Attribute"
          value={resource.attribute?.label || ""}
          fullWidth
          search={api.searchEligibilityAttributes}
          disabled={fixedAttribute}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("attribute", p)}
        />
        <FormControl disabled={fixedAssignee}>
          <FormLabel>Assignee Type</FormLabel>
          <RadioGroup value={assigneeType} row onChange={handleAssigneeTypeChange}>
            <FormControlLabel value="member" control={<Radio />} label="Member" />
            <FormControlLabel
              value="organization"
              control={<Radio />}
              label="Organization"
            />
            <FormControlLabel value="role" control={<Radio />} label="Role" />
          </RadioGroup>
        </FormControl>
        {assigneeType === "member" && (
          <AutocompleteSearch
            key="member"
            {...register("member")}
            label="Member"
            helperText="Assign this attribute to a member directly."
            value={resource.member?.label || ""}
            fullWidth
            search={api.searchMembers}
            disabled={fixedAssignee}
            style={{ flex: 1 }}
            onValueSelect={(mem) => setField("member", mem)}
            onTextChange={() => clearField("member")}
          />
        )}
        {assigneeType === "organization" && (
          <AutocompleteSearch
            key="org"
            {...register("organization")}
            label="Organization"
            helperText="All members of the organization get the attribute."
            value={resource.organization?.label || ""}
            fullWidth
            disabled={fixedAssignee}
            search={api.searchOrganizations}
            style={{ flex: 1 }}
            onValueSelect={(org) => setField("organization", org)}
            onTextChange={() => clearField("organization")}
          />
        )}
        {assigneeType === "role" && (
          <AutocompleteSearch
            key="role"
            {...register("role")}
            label="Role"
            helperText="All members with this role, or with membership in an organization with this role, get the attribute."
            value={resource.role?.label || ""}
            fullWidth
            search={api.searchRoles}
            searchEmpty={true}
            disabled={fixedAssignee}
            style={{ flex: 1 }}
            onValueSelect={(role) => setField("role", role)}
            onTextChange={() => clearField("role")}
          />
        )}
      </Stack>
    </FormLayout>
  );
}
