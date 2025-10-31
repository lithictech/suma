import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import VendorServiceCategoryDetailPage from "./VendorServiceCategoryDetailPage";
import { Stack, TextField } from "@mui/material";
import get from "lodash/get";
import React from "react";

export default function VendorServiceCategoryForm({
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
      title={isCreate ? "Create a Category" : "Update Category"}
      subtitle="Categories are associated things that can be purchased
      (products, services) and ledgers which can be used to pay for them."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("name")}
          label="Internal Name"
          name="name"
          value={resource.name}
          required
          fullWidth
          helperText="Name of the category."
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("slug")}
          label="External Name"
          name="slug"
          value={resource.slug}
          fullWidth
          helperText="Unique slug. This will be auto-generated on create if blank."
          onChange={setFieldFromInput}
        />
        <VendorServiceCategorySelect
          {...register("parent")}
          label="Parent"
          helperText="Categories are hierarchical.
          Products and services in a more specific category can be
          paid for by ledgers with the same or a parent category."
          value={get(resource, "parent.slug") || ""}
          style={{ flex: 1 }}
          onChange={(_, c) => setField("parent", c)}
          required
        />
      </Stack>
    </FormLayout>
  );
}
