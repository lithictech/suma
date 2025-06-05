import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function VendorForm({
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
      title={isCreate ? "Create a Vendor" : "Update Vendor"}
      subtitle="Vendor represents a vendor of goods and services, like 'Alan's Farm'. It is tied
        to a product. Suma does a wholesale purchase from a vendor. It then lists those
        products, and takes responsibility for inventory and fulfillment."
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
          {...register("name")}
          label="Name"
          name="name"
          value={resource.name}
          fullWidth
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
