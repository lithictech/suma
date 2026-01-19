import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import useMountEffect from "../shared/react/useMountEffect";
import { Stack } from "@mui/material";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function OfferingProductForm({
  isCreate,
  resource,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
  const [searchParams] = useSearchParams();
  useMountEffect(() => {
    if (searchParams.get("edit")) {
      return;
    }
    const offeringId = Number(searchParams.get("offeringId") || -1);
    const productId = Number(searchParams.get("productId") || -1);
    if (offeringId > 0) {
      setField("offering", {
        id: offeringId,
        label: searchParams.get("offeringLabel"),
      });
    }
    if (productId > 0) {
      setField("product", { id: productId, label: searchParams.get("productLabel") });
    }
  }, [searchParams]);

  return (
    <FormLayout
      title={isCreate ? "Create an Offering Product" : "Update Offering Product"}
      subtitle={
        isCreate
          ? "Offering Products associate a product and an offering, with the given prices."
          : "Offering Products associate a product and an offering, with the given prices. " +
            "Changing a price closes any existing offering products for this product/offering combo, " +
            "and creates a new (open) offering product with the given prices."
      }
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ResponsiveStack>
          <AutocompleteSearch
            {...register("offering")}
            label="Offering"
            helperText="To list the following product"
            value={resource.offering?.label || resource.offering?.description?.en}
            fullWidth
            required
            search={api.searchOfferings}
            disabled={Boolean(searchParams.get("offeringId") || searchParams.get("edit"))}
            style={{ flex: 1 }}
            onValueSelect={(o) => setField("offering", o)}
          />
          <AutocompleteSearch
            {...register("product")}
            label="Product"
            helperText="To be added to the chosen offering"
            value={resource.product?.label || resource.product?.name?.en}
            fullWidth
            required
            search={api.searchProducts}
            disabled={Boolean(searchParams.get("productId") || searchParams.get("edit"))}
            title={resource.product?.label}
            style={{ flex: 1 }}
            onValueSelect={(p) => setField("product", p)}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <CurrencyTextField
            {...register("customerPrice")}
            label="Customer Price"
            helperText="The price the member payments."
            money={resource.customerPrice}
            required
            style={{ flex: 1 }}
            onMoneyChange={(v) => setField("customerPrice", v)}
          />
          <CurrencyTextField
            {...register("undiscountedPrice")}
            label="Undiscounted Price"
            helperText="The product's full price. If there is no discount, this is the same as the customer price."
            money={resource.undiscountedPrice}
            required
            style={{ flex: 1 }}
            onMoneyChange={(v) => setField("undiscountedPrice", v)}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
