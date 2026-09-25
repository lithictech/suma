import api from "../api";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import {
  FormControl,
  FormControlLabel,
  FormLabel,
  Radio,
  RadioGroup,
  Stack,
} from "@mui/material";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useParams } from "react-router-dom";

export default function FundingTransactionRefundPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const { id } = useParams();

  const [mode, setMode] = React.useState("full");
  let defaultMoney = config.defaultZeroMoney;
  try {
    defaultMoney = JSON.parse(
      new URLSearchParams(window.location.search).get("refundableAmount")
    );
  } catch (e) {
    console.log(e);
  }
  const [amount, setAmount] = React.useState(defaultMoney);
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  function submit() {
    busy();
    const params = mode === "full" ? { full: true } : { amount };
    api
      .refundFundingTransaction({ id: Number(id), ...params })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }

  return (
    <FormLayout
      title="Refund a Funding Transaction"
      subtitle="Refund all or part of this transaction.
      The refund will be credited to whatever payment instrument (credit card, etc)
      the member used to pay."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormControl>
          <FormLabel>Amount</FormLabel>
          <RadioGroup value={mode} row onChange={(e) => setMode(e.target.value)}>
            <FormControlLabel value="full" control={<Radio />} label="Full" />
            <FormControlLabel value="partial" control={<Radio />} label="Partial" />
          </RadioGroup>
        </FormControl>
        <CurrencyTextField
          {...register("amount")}
          label="Amount"
          helperText="How much to refund?"
          money={amount}
          disabled={mode === "full"}
          sx={{ width: { xs: "100%", sm: "50%" } }}
          required
          onMoneyChange={setAmount}
        />
      </Stack>
    </FormLayout>
  );
}
