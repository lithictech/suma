import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import { FormLabel, Stack } from "@mui/material";
import React from "react";

export default function ProgramEnrollmentForm({
  isCreate,
  resource,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
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
          value={resource.program.adminlabel || ""}
          fullWidth
          search={api.searchPrograms}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("program.id", p.id)}
        />
        <FormLabel>Enrollee(s)</FormLabel>
        <ResponsiveStack alignItems="center" divider={<CompareArrowsIcon />}>
          <AutocompleteSearch
            {...register("member")}
            label="Member"
            helperText="Who can access this program?"
            value={resource.member.adminlabel || ""}
            fullWidth
            search={api.searchMembers}
            disabled={!!resource.organization.id}
            style={{ flex: 1 }}
            onValueSelect={(mem) => setField("member.id", mem.id)}
            onTextChange={() => setField("member.id", null)}
          />
          <AutocompleteSearch
            {...register("organization")}
            label="Organization"
            helperText="What organization can access this program?"
            value={resource.organization.adminlabel || ""}
            fullWidth
            disabled={!!resource.member.id}
            search={api.searchOrganizations}
            style={{ flex: 1 }}
            onValueSelect={(org) => setField("organization.id", org.id)}
            onTextChange={() => setField("organization.id", null)}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
