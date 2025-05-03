import api from "../api";
import FormLayout from "../components/FormLayout";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useUrlMarshal from "../hooks/useUrlMarshal";
import formatDate from "../modules/formatDate";
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Radio,
  RadioGroup,
  Stack,
  TextField,
} from "@mui/material";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useParams } from "react-router-dom";

export default function PaymentTriggerSubdividePage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const { id } = useParams();
  const { unmarshalFromUrl } = useUrlMarshal();

  const [unit, setUnit] = React.useState("week");
  const [amount, setAmount] = React.useState(1);
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  function submit() {
    busy();
    api
      .subdividePaymentTrigger({ id: Number(id), unit, amount })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }

  const model = unmarshalFromUrl("model", window.location.href);

  return (
    <FormLayout
      title="Subdivide a Payment Trigger"
      subtitle="Choose the interval for this payment trigger.
      New instances will be created for each interval.
      For example, a trigger active from April 1 to April 21st, subdivided by 1 week,
      will result in 3 triggers (April 1-7, 8-14, and 15-21)."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        {model && (
          <div>
            Trigger <strong>{model.label}</strong> is active
            <br />
            from <strong>{formatDate(model.activeDuringBegin)}</strong>
            <br />
            to <strong>{formatDate(model.activeDuringEnd)}</strong>.
          </div>
        )}
        <FormControl>
          <FormLabel>Unit</FormLabel>
          <RadioGroup value={unit} row onChange={(e) => setUnit(e.target.value)}>
            <FormControlLabel value="day" control={<Radio />} label="Day" />
            <FormControlLabel value="week" control={<Radio />} label="Week" />
            <FormControlLabel value="month" control={<Radio />} label="Month" />
          </RadioGroup>
        </FormControl>
        <TextField
          {...register("amount")}
          label="Amount"
          value={amount}
          sx={{ width: { xs: "100%", sm: "50%" } }}
          required
          type="number"
          onChange={(v) => setAmount(v.target.value)}
        />
      </Stack>
    </FormLayout>
  );
}
