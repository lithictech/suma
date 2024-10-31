import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import useMountEffect from "../shared/react/useMountEffect";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import { FormLabel, Stack } from "@mui/material";
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
  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
    }
    const memberId = Number(searchParams.get("memberId") || -1);
    const organizationId = Number(searchParams.get("organizationId") || -1);
    if (memberId > 0) {
      setField("member", { id: memberId, label: searchParams.get("memberLabel") });
    }
    if (organizationId > 0) {
      setField("organization", {
        id: organizationId,
        label: searchParams.get("organizationLabel"),
      });
    }
  }, [searchParams]);
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
        <FormLabel>Enrollee(s)</FormLabel>
        <ResponsiveStack alignItems="center" divider={<CompareArrowsIcon />}>
          <AutocompleteSearch
            {...register("member")}
            label="Member"
            helperText="Who can access this program?"
            value={resource.member?.label || ""}
            fullWidth
            search={api.searchMembers}
            disabled={!!resource.organization.id}
            style={{ flex: 1 }}
            onValueSelect={(mem) => setField("member", mem)}
            onTextChange={() => setField("member", {})}
          />
          <AutocompleteSearch
            {...register("organization")}
            label="Organization"
            helperText="What organization can access this program?"
            value={resource.organization.label || ""}
            fullWidth
            disabled={!!resource.member.id}
            search={api.searchOrganizations}
            style={{ flex: 1 }}
            onValueSelect={(org) => setField("organization", org)}
            onTextChange={() => setField("organization", {})}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
