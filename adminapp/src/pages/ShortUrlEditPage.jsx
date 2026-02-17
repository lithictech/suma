import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function ShortUrlEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getShortUrl}
      apiUpdate={api.updateShortUrl}
      Form={ShortUrlForm}
    />
  );
}

function ShortUrlForm({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Update Short URL"
      subtitle="This is a self-hosted URL shortener that can
      be used like other url shorteners. Note that it does not
      currently provide any analytics.
      You should use analytics at the target page instead."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("shortId")}
          label="Short ID"
          name="shortId"
          helperText="Leave blank to auto-generate a short ID."
          value={resource.shortId}
          fullWidth
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("longUrl")}
          label="URL"
          name="longUrl"
          helperText="The URL to shorten."
          value={resource.longUrl}
          fullWidth
          autoFocus
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
