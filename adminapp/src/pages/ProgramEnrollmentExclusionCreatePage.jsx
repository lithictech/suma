import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
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

export default function ProgramEnrollmentExclusionCreatePage() {
  const empty = {
    program: null,
    member: null,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createProgramEnrollmentExclusion}
      Form={Form}
    />
  );
}

function Form({ resource, setField, register, isBusy, onSubmit }) {
  const [searchParams] = useSearchParams();
  const searchProgramId = Number(searchParams.get("programId") || -1);
  const searchEnrolleeId = Number(searchParams.get("enrolleeId") || -1);
  const searchEnrolleeType = searchParams.get("enrolleeType");
  const [enrolleeType, setEnrolleeType] = React.useState(searchEnrolleeType || "member");
  const fixedEnrollee = searchEnrolleeId > 0;

  useMountEffect(() => {
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
    setField(enrolleeType, null);
  };

  return (
    <FormLayout
      title="Create Program Enrollment Exclusion"
      subtitle="Exclude a member's ability to access a program they otherwise have access to."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>Program Enrollment Exclusion</FormLabel>
        <AutocompleteSearch
          {...register("program")}
          label="Program"
          value={resource.program?.label || ""}
          fullWidth
          search={api.searchPrograms}
          required
          disabled={searchParams.has("programId")}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("program", p)}
        />
        <FormControl disabled={fixedEnrollee}>
          <FormLabel>Enrollee Type</FormLabel>
          <RadioGroup value={enrolleeType} row onChange={handleEnrolleeTypeChange}>
            <FormControlLabel value="member" control={<Radio />} label="Member" />
            <FormControlLabel value="role" control={<Radio />} label="Role" />
          </RadioGroup>
        </FormControl>
        {enrolleeType === "member" && (
          <AutocompleteSearch
            {...register("member")}
            label="Member"
            helperText="This member is excluded from this program."
            value={resource.member?.label || ""}
            fullWidth
            search={api.searchMembers}
            required
            disabled={searchParams.has("enrolleeId")}
            style={{ flex: 1 }}
            searchEmpty
            onValueSelect={(p) => setField("member", p)}
          />
        )}
        {enrolleeType === "role" && (
          <AutocompleteSearch
            key="role"
            {...register("role")}
            label="Role"
            helperText="Members (NOT organizations) with this role are excluded from this program."
            value={resource.role?.label || ""}
            fullWidth
            search={api.searchRoles}
            searchEmpty={true}
            disabled={fixedEnrollee}
            style={{ flex: 1 }}
            onValueSelect={(role) => setField("role", role)}
          />
        )}
      </Stack>
    </FormLayout>
  );
}
