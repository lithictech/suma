import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import { formatOrNull } from "../modules/dayConfig";
import RemoveIcon from "@mui/icons-material/Remove";
import {
  FormControl,
  FormHelperText,
  InputLabel,
  Select,
  Stack,
  TextField,
} from "@mui/material";
import MenuItem from "@mui/material/MenuItem";
import get from "lodash/get";
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
        <AutocompleteSearch
          {...register("vendor")}
          label="Vendor"
          value={resource.vendor.name || ""}
          fullWidth
          required
          search={api.searchVendors}
          disabled={!isCreate}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("vendor", p)}
        />
        <ResponsiveStack>
          <TextField
            {...register("internalName")}
            label="Internal Name"
            name="internalName"
            value={resource.internalName}
            required
            fullWidth
            onChange={setFieldFromInput}
          />
          <TextField
            {...register("externalName")}
            label="External Name"
            name="externalName"
            value={resource.externalName}
            required
            fullWidth
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
        <ResponsiveStack alignItems="center" divider={<RemoveIcon />}>
          <SafeDateTimePicker
            label="Open Date"
            value={resource.periodBegin}
            required
            onChange={(v) => setField("periodBegin", formatOrNull(v))}
          />
          <SafeDateTimePicker
            label="Close Date"
            value={resource.periodEnd}
            required
            onChange={(v) => setField("periodEnd", formatOrNull(v))}
          />
        </ResponsiveStack>
        <VendorServiceCategorySelect
          {...register("category")}
          label="Category"
          helperText="What ledger funds can be used to pay for this service?"
          value={get(resource, "categories.0.slug") || ""}
          style={{ flex: 1 }}
          onChange={(_, c) => setField("categories.0", c)}
          required
        />
        <FormControl>
          <InputLabel>Mobility Adapter</InputLabel>
          <Select
            {...register("mobilityAdapterSetting")}
            label="Mobility Adapter Key"
            name="mobilityAdapterSetting"
            value={resource.mobilityAdapterSetting}
            onChange={setFieldFromInput}
          >
            {resource.mobilityAdapterSettingOptions.map(({ name, value }) => (
              <MenuItem key={value} value={value}>
                {name}
              </MenuItem>
            ))}
          </Select>
          <FormHelperText>
            How this service maps to backend functionality. Generally a programmer will
            set this.
          </FormHelperText>
        </FormControl>
        <TextField
          {...register("constraints")}
          label="Constraints"
          name="constraints"
          value={
            typeof resource.constraints === "string"
              ? resource.constraints
              : JSON.stringify(resource.constraints)
          }
          onChange={setFieldFromInput}
          helperText={
            <span>
              JSON string defining GBFS constraints, like{" "}
              <code>{`[{"form_factor":"bicycle","propulsion_type":"electric_assist"}]`}</code>
              . Ask a programmer for more info.
            </span>
          }
        />
      </Stack>
    </FormLayout>
  );
}
