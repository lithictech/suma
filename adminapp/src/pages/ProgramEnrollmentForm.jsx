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

export default function ProgramEnrollmentForm({
  isCreate,
  resource,
  setField,
  clearField,
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  const searchProgramId = Number(searchParams.get("programId") || -1);
  const searchEnrolleeId = Number(searchParams.get("enrolleeId") || -1);
  const searchEnrolleeType = searchParams.get("enrolleeType");
  const [enrolleeType, setEnrolleeType] = React.useState(searchEnrolleeType || "member");
  const fixedEnrollee = searchEnrolleeId > 0;

  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
    }
    if (searchProgramId > 0) {
      setField("program", {
        id: searchProgramId,
        label: searchParams.get("programLabel"),
      });
    }
    if (searchEnrolleeId > 0) {
      setField(searchEnrolleeType, {
        id: searchEnrolleeId,
        label: searchParams.get("enrolleeLabel"),
      });
    }
  }, [searchParams]);

  const handleEnrolleeTypeChange = (e) => {
    setEnrolleeType(e.target.value);
    clearField(enrolleeType);
  };
  return (
    <FormLayout
      title={isCreate ? "Create a Program Enrollment" : "Update a Program Enrollment"}
      subtitle="Program enrollment that are approved gives access to a member,
      members in an organization, or members with a role to resources connected
      with an active program. After creation, you can approve the enrollment and/or unenroll."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>Program</FormLabel>
        <AutocompleteSearch
          {...register("program")}
          label="Program"
          value={resource.program.label || ""}
          fullWidth
          required
          search={api.searchPrograms}
          disabled={searchProgramId > 0}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("program", p)}
        />
        <FormControl disabled={fixedEnrollee}>
          <FormLabel>Enrollee Type</FormLabel>
          <RadioGroup value={enrolleeType} row onChange={handleEnrolleeTypeChange}>
            <FormControlLabel value="member" control={<Radio />} label="Member" />
            <FormControlLabel
              value="organization"
              control={<Radio />}
              label="Organization"
            />
            <FormControlLabel value="role" control={<Radio />} label="Role" />
          </RadioGroup>
        </FormControl>
        {enrolleeType === "member" && (
          <AutocompleteSearch
            key="member"
            {...register("member")}
            label="Member"
            helperText="Who can access this program?"
            value={resource.member?.label || ""}
            fullWidth
            search={api.searchMembers}
            disabled={fixedEnrollee}
            style={{ flex: 1 }}
            onValueSelect={(mem) => setField("member", mem)}
            onTextChange={() => clearField("member")}
          />
        )}
        {enrolleeType === "organization" && (
          <AutocompleteSearch
            key="org"
            {...register("organization")}
            label="Organization"
            helperText="What members in this organization can access this program?"
            value={resource.organization?.label || ""}
            fullWidth
            disabled={fixedEnrollee}
            search={api.searchOrganizations}
            style={{ flex: 1 }}
            onValueSelect={(org) => setField("organization", org)}
            onTextChange={() => clearField("organization")}
          />
        )}
        {enrolleeType === "role" && (
          <AutocompleteSearch
            key="role"
            {...register("role")}
            label="Role"
            helperText="What members with this role can access this program?"
            value={resource.role?.label || ""}
            fullWidth
            search={api.searchRoles}
            searchEmpty={true}
            disabled={fixedEnrollee}
            style={{ flex: 1 }}
            onValueSelect={(role) => setField("role", role)}
            onTextChange={() => clearField("role")}
          />
        )}
      </Stack>
    </FormLayout>
  );
}
