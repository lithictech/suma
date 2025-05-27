import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import { FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

export default function MarketingSmsBroadcastCreatePage() {
  const empty = {
    label: "",
  };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createMarketingSmsBroadcast}
      Form={CreateForm}
    />
  );
}

function CreateForm({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Create an SMS Marketing Broadcast"
      subtitle="Broadcasts are messages that can be sent to multiple members through Marketing Lists."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>SMS Broadcast</FormLabel>
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
