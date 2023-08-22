import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormButtons from "../components/FormButtons";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress, Stack, TextField, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function BookTransactionCreatePage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [originatingLedgerId, setOriginatingLedgerId] = React.useState(0);
  const [receivingLedgerId, setReceivingLedgerId] = React.useState(0);
  const [amount, setAmount] = React.useState(config.defaultZeroMoney);
  const [memo, setMemo] = React.useState("");
  const [category, setCategory] = React.useState("");
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  const {
    state: receivingLedger,
    loading: receivingLedgerLoading,
    asyncFetch: receivingLedgerFetch,
  } = useAsyncFetch(api.searchLedger, {
    default: null,
    pickData: true,
    doNotFetchOnInit: true,
  });
  const {
    state: originatingLedger,
    loading: originatingLedgerLoading,
    asyncFetch: originatingLedgerFetch,
  } = useAsyncFetch(api.searchLedger, {
    default: null,
    pickData: true,
    doNotFetchOnInit: true,
  });

  const originatingLedgerIdFromURL = Number(searchParams.get("originatingLedgerId"));
  const receivingLedgerIdFromURL = Number(searchParams.get("receivingLedgerId"));

  React.useEffect(() => {
    if (originatingLedgerIdFromURL && !originatingLedger) {
      originatingLedgerFetch({ id: originatingLedgerIdFromURL })
        .then(() => {
          setOriginatingLedgerId(originatingLedgerIdFromURL);
        })
        .catch((e) => enqueueErrorSnackbar(e));
    }
  }, [
    originatingLedgerIdFromURL,
    enqueueErrorSnackbar,
    originatingLedger,
    originatingLedgerFetch,
    originatingLedgerId,
  ]);

  React.useEffect(() => {
    if (receivingLedgerIdFromURL && !receivingLedger) {
      receivingLedgerFetch({ id: receivingLedgerIdFromURL })
        .then(() => {
          setReceivingLedgerId(receivingLedgerIdFromURL);
        })
        .catch((e) => enqueueErrorSnackbar(e));
    }
  }, [
    receivingLedgerIdFromURL,
    enqueueErrorSnackbar,
    receivingLedger,
    receivingLedgerFetch,
    receivingLedgerId,
  ]);

  function submit() {
    busy();
    api
      .createBookTransaction({
        originatingLedgerId,
        receivingLedgerId,
        amount,
        memo,
        vendorServiceCategorySlug: category,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }

  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create a Book Transaction
      </Typography>
      <Typography variant="body1" gutterBottom>
        Book transactions move virtual money from one ledger to another. They do NOT add
        funds onto the platform.
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
            <div>
              <VendorServiceCategorySelect
                {...register("category")}
                label="Category"
                helperText="What can this be used for?"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              />
            </div>
            <TextField
              {...register("memo")}
              label="Memo"
              helperText="This shows on the ledger."
              fullWidth
              value={memo}
              required
              onChange={(e) => setMemo(e.target.value)}
            />
          </Stack>
          <Stack direction="row" spacing={2}>
            {originatingLedgerLoading ? (
              <LoadingInputPlaceholder helperText="Where is the money coming from?" />
            ) : (
              <AutocompleteSearch
                {...register("originatingLedger")}
                label="Originating Ledger"
                helperText="Where is the money coming from?"
                defaultValue={originatingLedger?.label}
                fullWidth
                required
                search={api.searchLedgers}
                onValueSelect={(o) => setOriginatingLedgerId(o?.id || 0)}
              />
            )}
            {receivingLedgerLoading ? (
              <LoadingInputPlaceholder helperText="Where is the money going?" />
            ) : (
              <AutocompleteSearch
                {...register("receivingLedger")}
                label="Receiving Ledger"
                helperText="Where is the money going?"
                defaultValue={receivingLedger?.label}
                fullWidth
                required
                search={api.searchLedgers}
                onValueSelect={(o) => setReceivingLedgerId(o?.id || 0)}
              />
            )}
          </Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}

function LoadingInputPlaceholder({ helperText }) {
  return (
    <TextField
      id={helperText}
      helperText={helperText}
      label={<CircularProgress size="1rem" />}
      disabled
      fullWidth
    />
  );
}
