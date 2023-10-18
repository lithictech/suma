import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormButtons from "../components/FormButtons";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { Stack, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function FundingTransactionCreatePage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const [paymentInstrument, setPaymentInstrument] = React.useState(null);
  const [amount, setAmount] = React.useState(config.defaultZeroMoney);
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  function submit() {
    busy();
    api
      .createForSelfFundingTransaction({
        paymentInstrumentId: paymentInstrument.id,
        paymentMethodType: paymentInstrument.paymentMethodType,
        amount,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }

  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create a Funding Transaction
      </Typography>
      <Typography variant="body1" gutterBottom>
        Funding Transactions add funds onto the platform, and moves funds into the
        platform ledger. Creating a Funding Transaction will also create a Book
        Transaction which will transfer the same amount of funds from the platform to the
        member&rsquo;s cash ledger.
      </Typography>
      <Box component="form" mt={2} onSubmit={handleSubmit(submit)}>
        <Stack spacing={2} direction="column">
          <Stack direction="row" spacing={2} alignItems="self-start">
            <CurrencyTextField
              {...register("amount")}
              label="Amount"
              helperText="How much is going from originator to receiver?"
              money={amount}
              required
              onMoneyChange={setAmount}
            />
            <AutocompleteSearch
              {...register("instrument")}
              label="Payment Instrument"
              helperText="Where are we debiting the money from?"
              fullWidth
              required
              search={api.searchPaymentInstruments}
              onValueSelect={(o) => setPaymentInstrument(o)}
            />
          </Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
