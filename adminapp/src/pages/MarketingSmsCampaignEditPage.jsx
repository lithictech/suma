import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import MarketingSmsCampaignCreatePage from "./MarketingSmsCampaignCreatePage";
import ProgramForm from "./ProgramForm";
import { FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

export default function MarketingSmsCampaignEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getMarketingSmsCampaign}
      apiUpdate={api.updateMarketingSmsCampaign}
      Form={EditForm}
    />
  );
}

function EditForm({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Update SMS Campaign"
      subtitle="Campaigns are sent to all members on all the associated lists.
      The body can use merge fields, including {{name}}, {{phone}}, and {{email}}.
      The body preview is done using your current user."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>SMS Campaign</FormLabel>
        <TextField
          {...register("label")}
          label="Label"
          name="label"
          value={resource.label || ""}
          type="text"
          variant="outlined"
          fullWidth
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
