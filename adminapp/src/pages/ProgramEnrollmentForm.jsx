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
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  const searchEnrolleeId = Number(searchParams.get("enrolleeId") || -1);
  const searchEnrolleeType = searchParams.get("enrolleeType");
  const [enrolleeType, setEnrolleeType] = React.useState(searchEnrolleeType || "member");
  const fixedEnrollee = searchEnrolleeId > 0;

  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
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
    setField(enrolleeType, {});
  };
  return (
    <FormLayout
      title={isCreate ? "Create a Program Enrollment" : "Update a Program Enrollment"}
      subtitle="Program enrollment that are approved gives access to a member
      or members in an organization to resources connected with an active program.
      After creation, you can approve the enrollment and/or unenroll."
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
          </RadioGroup>
        </FormControl>
        {enrolleeType === "member" ? (
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
            onTextChange={() => setField("member", {})}
          />
        ) : (
          <AutocompleteSearch
            key="org"
            {...register("organization")}
            label="Organization"
            helperText="What members in this organization can access this program?"
            value={resource.organization.label || ""}
            fullWidth
            disabled={fixedEnrollee}
            search={api.searchOrganizations}
            style={{ flex: 1 }}
            onValueSelect={(org) => setField("organization", org)}
            onTextChange={() => setField("organization", {})}
          />
        )}
      </Stack>
    </FormLayout>
  );
}
