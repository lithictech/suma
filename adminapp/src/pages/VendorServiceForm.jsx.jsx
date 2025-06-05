import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import RemoveIcon from "@mui/icons-material/Remove";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function VendorServiceForm({
  isCreate,
  resource,
  setField,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create a Vendor Service" : "Update Vendor Service"}
      subtitle="Vendor services are another type of 'good' that can be sold,
       similar to commerce offerings. It is currently used for more complex
       vendor service setups like the Lime integration."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ImageFileInput
          image={resource.image}
          caption={resource.imageCaption}
          required={isCreate}
          onImageChange={(f) => setField("image", f)}
          onCaptionChange={(f) => setField("imageCaption", f)}
        />
        <TextField
          {...register("externalName")}
          label="Name"
          name="externalName"
          value={resource.externalName}
          fullWidth
          onChange={setFieldFromInput}
        />
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <SafeDateTimePicker
            label="Open Date"
            value={resource.periodBegin}
            onChange={(v) => setField("periodBegin", formatOrNull(v))}
          />
          <SafeDateTimePicker
            label="Close Date"
            value={resource.periodEnd}
            onChange={(v) => setField("periodEnd", formatOrNull(v))}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
