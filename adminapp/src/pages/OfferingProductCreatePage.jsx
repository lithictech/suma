import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useMountEffect from "../shared/react/useMountEffect";
import { Stack } from "@mui/material";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function OfferingProductCreatePage() {
  const navigate = useNavigate();
  const [offering, setOffering] = React.useState(null);
  const [product, setProduct] = React.useState(null);
  const [customerPrice, setCustomerPrice] = React.useState(config.defaultZeroMoney);
  const [undiscountedPrice, setUndiscountedPrice] = React.useState(
    config.defaultZeroMoney
  );
  const [searchParams] = useSearchParams();
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();
  //
  useMountEffect(() => {
    const offeringId = Number(searchParams.get("offeringId") || -1);
    const offeringDescription = searchParams.get("offeringDescription");
    const productId = Number(searchParams.get("productId") || -1);
    const productName = searchParams.get("productName");
    if (offeringId === -1 && productId === -1) {
      // No params are in the URL so we don't search
      return;
    }
    if (offeringId && offeringDescription) {
      setOffering({ id: offeringId, label: offeringDescription });
    }
    if (productId && productName) {
      setProduct({ id: productId, label: productName });
    }
  }, [searchParams, enqueueErrorSnackbar]);

  const submit = () => {
    busy();
    api
      .createCommerceOfferingProduct({
        offeringId: offering.id,
        productId: product.id,
        customerPrice,
        undiscountedPrice,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <FormLayout
      title="Create an Offering Product"
      subtitle="This adds any product to any offering. The product will be listed in the offering at the set customer price."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ResponsiveStack>
          <AutocompleteSearch
            {...register("offering")}
            label="Offering"
            helperText="To list the following product"
            value={offering?.label}
            fullWidth
            required
            search={api.searchOfferings}
            disabled={
              Boolean(searchParams.get("offeringId")) &&
              Boolean(searchParams.get("offeringDescription"))
            }
            title={offering?.label}
            style={{ flex: 1 }}
            onValueSelect={(o) => setOffering(o)}
          />
          <AutocompleteSearch
            {...register("product")}
            label="Product"
            helperText="To be added to the chosen offering"
            value={product?.label}
            fullWidth
            required
            search={api.searchProducts}
            disabled={
              Boolean(searchParams.get("productId")) &&
              Boolean(searchParams.get("productName"))
            }
            title={product?.label}
            style={{ flex: 1 }}
            onValueSelect={(p) => setProduct(p)}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <CurrencyTextField
            {...register("customerPrice")}
            label="Customer Price"
            helperText="Whats the member's final price?"
            money={customerPrice}
            required
            style={{ flex: 1 }}
            onMoneyChange={setCustomerPrice}
          />
          <CurrencyTextField
            {...register("undiscountedPrice")}
            label="Undiscounted Price"
            helperText="The product's full price. If there is no discount, set this as the customer price."
            money={undiscountedPrice}
            required
            style={{ flex: 1 }}
            onMoneyChange={setUndiscountedPrice}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
