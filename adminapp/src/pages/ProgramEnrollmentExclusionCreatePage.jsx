import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import useMountEffect from "../shared/react/useMountEffect";
import { FormLabel, Stack } from "@mui/material";
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
  useMountEffect(() => {
    const programId = Number(searchParams.get("programId") || -1);
    const memberId = Number(searchParams.get("memberId") || -1);
    if (programId > 0) {
      setField("program", { id: programId, label: searchParams.get("programLabel") });
    }
    if (memberId > 0) {
      setField("member", { id: memberId, label: searchParams.get("memberLabel") });
    }
  }, [searchParams]);

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
        <AutocompleteSearch
          {...register("member")}
          label="Member"
          value={resource.member?.label || ""}
          fullWidth
          search={api.searchMembers}
          required
          disabled={searchParams.has("memberId")}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("member", p)}
        />
      </Stack>
    </FormLayout>
  );
}
