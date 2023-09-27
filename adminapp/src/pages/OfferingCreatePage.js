import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormButtons from "../components/FormButtons";
import MultiLingualText from "../components/MultiLingualText";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useMountEffect from "../shared/react/useMountEffect";
import { FormLabel, Stack, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import humps from "humps";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function OfferingCreatePage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [period, setPeriod] = React.useState([]);
  const [description, setDescription] = React.useState({ en: "", es: "" });
  const [fulfillmentPrompt, setFulfillmentPrompt] = React.useState({ en: "", es: "" });
  const [fulfillmentConfirmation, setFulfillmentConfirmation] = React.useState({
    en: "",
    es: "",
  });
  const [fulfillmentOptions, setFulfillmentOptions] = React.useState([]);
  const [eligibilityConstraints, setEligibilityConstraints] = React.useState([]);
  const [beginFulfillmentAt, setBeginFulfillmentAt] = React.useState(null);

  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  // useMountEffect(() => {
  //   // If the ID is 0, set the ledger by the platform category.
  //   // If the ID is > 0, it should be set with an ID lookup from the backend.
  //   const originatingLedgerId = Number(searchParams.get("originatingLedgerId") || -1);
  //   const receivingLedgerId = Number(searchParams.get("receivingLedgerId") || -1);
  //   const categorySlug = searchParams.get("vendorServiceCategorySlug");
  //   if (originatingLedgerId === -1 && receivingLedgerId === -1 && !categorySlug) {
  //     // No params are in the URL so we don't search
  //     return;
  //   }
  //   api
  //     .searchLedgersLookup({
  //       ids: [originatingLedgerId, receivingLedgerId].filter((x) => x > 0),
  //       platformCategories: [categorySlug].filter(Boolean),
  //     })
  //     .then((r) => {
  //       const { byId, platformByCategory } = r.data;
  //       if (originatingLedgerId === 0) {
  //         setOriginatingLedger(platformByCategory[humps.camelize(categorySlug)]);
  //       } else if (originatingLedgerId > 0) {
  //         setOriginatingLedger(byId[originatingLedgerId]);
  //       }
  //       if (receivingLedgerId === 0) {
  //         setReceivingLedger(platformByCategory[humps.camelize(categorySlug)]);
  //       } else if (receivingLedgerId > 0) {
  //         setReceivingLedger(byId[receivingLedgerId]);
  //       }
  //     })
  //     .catch(enqueueErrorSnackbar);
  // }, [searchParams, enqueueErrorSnackbar]);

  function submit() {
    busy();
    // api
    //   .createOffering({
    //     originatingLedgerId: originatingLedger?.id,
    //     receivingLedgerId: receivingLedger?.id,
    //     amount,
    //     memo,
    //     vendorServiceCategorySlug: category?.slug,
    //   })
    //   .then(api.followRedirect(navigate))
    //   .tapCatch(notBusy)
    //   .catch(enqueueErrorSnackbar);
  }
  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create an Offering
      </Typography>
      <Typography variant="body1" gutterBottom>
        Offerings holds products that can be ordered at checkout. They are only available
        during their period.
      </Typography>
      <Box component="form" mt={2} onSubmit={handleSubmit(submit)}>
        <Stack spacing={2} direction="column">
          <FormLabel>Description:</FormLabel>
          <Stack direction="row" spacing={2}>
            <MultiLingualText
              {...register("description")}
              label="Description"
              fullWidth
              value={description}
              required
              searchParams={{ types: ["description"] }}
              onChange={(description) => setDescription(description)}
            />
          </Stack>
          <FormLabel>Fulfillment Prompt:</FormLabel>
          <Stack direction="row" spacing={2}>
            <MultiLingualText
              {...register("fulfillmentPrompt")}
              label="Fulfillment Prompt"
              fullWidth
              value={fulfillmentPrompt}
              required
              searchParams={{ types: ["fulfillmentPrompt"] }}
              onChange={(fulfillmentPrompt) => setFulfillmentPrompt(fulfillmentPrompt)}
            />
          </Stack>
          <FormLabel>Fulfillment Confirmation:</FormLabel>
          <Stack direction="row" spacing={2}>
            <MultiLingualText
              {...register("fulfillmentConfirmation")}
              label="Fulfillment Confirmation"
              fullWidth
              value={fulfillmentConfirmation}
              required
              searchParams={{ types: ["fulfillmentConfirmation"] }}
              onChange={(fulfillmentConfirmation) =>
                setFulfillmentConfirmation(fulfillmentConfirmation)
              }
            />
          </Stack>
          <Stack direction="row" spacing={2}></Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
