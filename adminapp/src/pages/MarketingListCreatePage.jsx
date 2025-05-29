import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import { FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

export default function MarketingListCreatePage() {
  const empty = {
    label: "",
  };

  return (
    <ResourceCreate empty={empty} apiCreate={api.createMarketingList} Form={CreateForm} />
  );
}

function CreateForm({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Create a Marketing List"
      subtitle="Broadcasts are sent to lists. We should generally use
      Managed (auto-created and updated) lists,
      but sometimes we want manual lists too."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>Marketing List</FormLabel>
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
