import api from "../api";
import FormButtons from "../components/FormButtons";
import MultiLingualText from "../components/MultiLingualText";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import RemoveIcon from "@mui/icons-material/Remove";
import {
  Divider,
  FormControlLabel,
  FormLabel,
  Stack,
  Switch,
  Typography,
} from "@mui/material";
import Box from "@mui/material/Box";
import { DateTimePicker } from "@mui/x-date-pickers";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function OfferingCreatePage() {
  // TODO: Add ability to add fulfillment options
  const navigate = useNavigate();
  const translationObj = { en: "", es: "" };
  const [description, setDescription] = React.useState(translationObj);
  const [fulfillmentPrompt, setFulfillmentPrompt] = React.useState(translationObj);
  const [fulfillmentConfirmation, setFulfillmentConfirmation] =
    React.useState(translationObj);
  const [periodBegin, setPeriodBegin] = React.useState(null);
  const [periodEnd, setPeriodEnd] = React.useState(null);
  const [beginFulfillmentAt, setBeginFulfillmentAt] = React.useState(null);
  const [prohibitChargeAtCheckout, setProhibitChargeAtCheckout] = React.useState(false);
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  function submit() {
    busy();
    api
      .createCommerceOffering({
        description,
        fulfillmentPrompt,
        fulfillmentConfirmation,
        periodBegin: periodBegin.format(),
        periodEnd: periodEnd.format(),
        beginFulfillmentAt: beginFulfillmentAt && beginFulfillmentAt.format(),
        prohibitChargeAtCheckout,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
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
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <MultiLingualText
              {...register("description")}
              label="Description"
              fullWidth
              value={description}
              required
              onChange={(description) => setDescription(description)}
            />
          </Stack>
          <FormLabel>Fulfillment Prompt (for checkout):</FormLabel>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <MultiLingualText
              {...register("fulfillmentPrompt")}
              label="Fulfillment Prompt"
              fullWidth
              value={fulfillmentPrompt}
              required
              onChange={(fulfillmentPrompt) => setFulfillmentPrompt(fulfillmentPrompt)}
            />
          </Stack>
          <FormLabel>Fulfillment Confirmation (for checkout):</FormLabel>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <MultiLingualText
              {...register("fulfillmentConfirmation")}
              label="Fulfillment Confirmation"
              fullWidth
              value={fulfillmentConfirmation}
              required
              onChange={(fulfillmentConfirmation) =>
                setFulfillmentConfirmation(fulfillmentConfirmation)
              }
            />
          </Stack>
          <FormLabel>Period:</FormLabel>
          <Stack
            direction={{ xs: "column", sm: "row" }}
            alignItems="center"
            spacing={2}
            divider={<RemoveIcon />}
          >
            <DateTimePicker
              label="Beginning date *"
              value={periodBegin}
              onChange={(date) => setPeriodBegin(date)}
              sx={{ width: "100%" }}
            />
            <DateTimePicker
              label="Ending date *"
              value={periodEnd}
              onChange={(date) => setPeriodEnd(date)}
              sx={{ width: "100%" }}
            />
          </Stack>
          <Divider />
          <Typography variant="h6">Optional</Typography>
          <FormLabel>Begin Fulfillment Date (of orders):</FormLabel>
          <DateTimePicker
            label="Begin At"
            value={beginFulfillmentAt}
            onChange={(date) => setBeginFulfillmentAt(date)}
            onClose={() => setBeginFulfillmentAt(null)}
            sx={{ width: "50%" }}
          />
          <Stack direction="row" spacing={2}>
            <FormControlLabel
              control={<Switch />}
              label="Prohibit Charge At Checkout"
              checked={prohibitChargeAtCheckout}
              onChange={() => setProhibitChargeAtCheckout(!prohibitChargeAtCheckout)}
            />
          </Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
