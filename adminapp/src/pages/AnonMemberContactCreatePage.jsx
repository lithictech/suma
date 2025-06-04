import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Radio,
  RadioGroup,
  Stack,
} from "@mui/material";
import React from "react";

export default function AnonMemberContactCreatePage() {
  return (
    <ResourceCreate
      empty={{ type: "", member: null }}
      apiCreate={api.provisionAnonMemberContact}
      Form={CreateForm}
    />
  );
}

function CreateForm({ resource, setField, register, isBusy, onSubmit }) {
  let helperText = <span>Who is this contact for?</span>;
  if (resource.type === "phone") {
    helperText = (
      <>
        {helperText}
        <br />
        NOTE: This will provision a phone number, which incurs a monthly charge. Destroy
        this contact when you are done with the phone number.
      </>
    );
  }
  return (
    <FormLayout
      title="Provision Anonymous Member Contact"
      subtitle="Anonymous member contacts are usually automatically created by the Private/External Account system.
      You can manually create one for a member, if one of the given type (phone, email) does not exist.
      This may be useful for testing purposes, by provisioning a phone number that provides SMS-forwarding."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormControl>
          <FormLabel>Type</FormLabel>
          <RadioGroup
            value={resource.type}
            row
            onChange={(e) => setField("type", e.target.value)}
          >
            <FormControlLabel value="email" control={<Radio />} label="Email" />
            <FormControlLabel value="phone" control={<Radio />} label="Phone" />
          </RadioGroup>
        </FormControl>
        <AutocompleteSearch
          {...register("member")}
          label="Member"
          helperText={helperText}
          value={resource.member?.name || ""}
          fullWidth
          required
          search={api.searchMembers}
          style={{ flex: 1 }}
          onValueSelect={(o) => setField("member", o)}
        />
      </Stack>
    </FormLayout>
  );
}
