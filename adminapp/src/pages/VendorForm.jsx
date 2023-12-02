import FormLayout from "../components/FormLayout";
import { TextField } from "@mui/material";
import React from "react";

export default function VendorForm({
  isCreate,
  resource,
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
      <TextField
        {...register("name")}
        label="Name"
        name="name"
        value={resource.name}
        fullWidth
        onChange={setFieldFromInput}
      />
    </FormLayout>
  );
}
