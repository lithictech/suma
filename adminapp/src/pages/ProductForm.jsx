import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ImageFileInput from "../components/ImageFileInput";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import theme from "../theme";
import {
  FormControlLabel,
  FormLabel,
  Stack,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import get from "lodash/get";
import React from "react";

export default function ProductForm({
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
      title={isCreate ? "Create a Product" : "Edit Product"}
      subtitle=" A product is abstract, it can represent different goods. It is tied to a Vendor
        and can later be listed with an Offering, a.k.a OfferingProduct. If the Offering
        and Product are available on the platform, product will appear in the Food list
        and details page. Discount price can be set when creating an OfferingProduct."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ImageFileInput
          image={resource.image}
          caption={resource.imageCaption}
          onImageChange={(f) => setField("image", f)}
          onCaptionChange={(f) => setField("imageCaption", f)}
          required={isCreate}
        />
        <Stack spacing={2}>
          <FormLabel>Name:</FormLabel>
          <ResponsiveStack>
            <MultiLingualText
              {...register("name")}
              label="Name"
              fullWidth
              value={resource.name}
              required
              onChange={(v) => setField("name", v)}
            />
          </ResponsiveStack>
        </Stack>
        <FormLabel>Description:</FormLabel>
        <Stack spacing={2}>
          <MultiLingualText
            {...register("description")}
            label="Description"
            fullWidth
            value={resource.description}
            required
            multiline
            onChange={(v) => setField("description", v)}
          />
        </Stack>
        <ResponsiveStack sx={{ pt: theme.spacing(2) }}>
          <CurrencyTextField
            {...register("ourCost")}
            label="Our Cost"
            helperText="How much does suma offer this product for?"
            money={resource.ourCost}
            required
            style={{ flex: 1 }}
            onMoneyChange={(v) => setField("ourCost", v)}
          />
          <AutocompleteSearch
            {...register("vendor")}
            label="Vendor"
            helperText="What vendor offers this product?"
            value={resource.vendor?.label || resource.vendor?.name || ""}
            required
            search={api.searchVendors}
            style={{ flex: 1 }}
            searchEmpty
            onValueSelect={(v) => setField("vendor", v)}
          />
          <VendorServiceCategorySelect
            {...register("category")}
            label="Category"
            helperText="What ledger funds can be used to purchase this product?"
            value={get(resource, "vendorServiceCategories.0.slug") || ""}
            style={{ flex: 1 }}
            onChange={(_, c) => setField("vendorServiceCategories.0", c)}
            required
          />
        </ResponsiveStack>
        <Typography variant="h6">Inventory</Typography>
        <ResponsiveStack>
          <TextField
            name="inventory.maxQuantityPerMemberPerOffering"
            value={resource.inventory.maxQuantityPerMemberPerOffering || ""}
            type="number"
            label="Max per Member/Offering"
            helperText="The maximum a single member can purchase within a single offering. Empty if unenforced."
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <FormControlLabel
            control={<Switch />}
            label="Limited Quantity"
            name="inventory.limitedQuantity"
            checked={resource.inventory.limitedQuantity}
            onChange={setFieldFromInput}
          />
          <TextField
            name="inventory.quantityOnHand"
            value={resource.inventory.quantityOnHand}
            type="number"
            label="Quantity On Hand"
            helperText="How much of the product do we have available."
            onChange={setFieldFromInput}
          />
          <TextField
            name="inventory.quantityPendingFulfillment"
            value={resource.inventory.quantityPendingFulfillment}
            type="number"
            label="Quantity Pending Fulfillment"
            helperText="How much of the product is assigned to unfulfilled orders. Usually automatically managed."
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
