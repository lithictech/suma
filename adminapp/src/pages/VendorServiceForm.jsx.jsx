import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import ResponsiveStack from "../components/ResponsiveStack";
import { dayjsOrNull, formatOrNull } from "../modules/dayConfig";
import RemoveIcon from "@mui/icons-material/Remove";
import { Stack, TextField } from "@mui/material";
import { DateTimePicker } from "@mui/x-date-pickers";
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
          required={isCreate}
          onImageChange={(f) => setField("image", f)}
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
          <DateTimePicker
            label="Open Date"
            value={dayjsOrNull(resource.periodBegin)}
            closeOnSelect
            onChange={(v) => setField("periodBegin", formatOrNull(v))}
            sx={{ width: "100%" }}
          />
          <DateTimePicker
            label="Close Date"
            value={dayjsOrNull(resource.periodEnd)}
            onChange={(v) => setField("periodEnd", formatOrNull(v))}
            closeOnSelect
            sx={{ width: "100%" }}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
