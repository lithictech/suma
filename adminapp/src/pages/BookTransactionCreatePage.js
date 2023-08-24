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
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";
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

  const ledgerData = useLedgers({
    search: api.searchReceivingLedger,
    onSetLedgers: (ledgers) => {
      if (isEmpty(ledgers)) {
        return;
      }
      setReceivingLedgerId(Number(ledgers.receivingLedger.id));
      setOriginatingLedgerId(Number(ledgers.platformLedger.id));
    },
  });

  React.useEffect(() => {
    if (!isEmpty(ledgerData.ledgers)) {
      return;
    }
    ledgerData.initializeToReceivingLedger(Number(searchParams.get("receivingLedgerId")));
  }, [searchParams, ledgerData, enqueueErrorSnackbar]);

  const receivingLedgerLabel = get(ledgerData, "ledgers.receivingLedger.label");
  const platformLedgerLabel = get(ledgerData, "ledgers.platformLedger.label");

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
            {ledgerData.ledgersLoading ? (
              <>
                <LoadingInputPlaceholder helperText="Where is the money coming from?" />
                <LoadingInputPlaceholder helperText="Where is the money going?" />
              </>
            ) : (
              <>
                <AutocompleteSearch
                  {...register("originatingLedger")}
                  label="Originating Ledger"
                  helperText="Where is the money coming from?"
                  defaultValue={platformLedgerLabel}
                  fullWidth
                  required
                  search={api.searchLedgers}
                  onValueSelect={(o) => setOriginatingLedgerId(o?.id || 0)}
                />
                <AutocompleteSearch
                  {...register("receivingLedger")}
                  label="Receiving Ledger"
                  helperText="Where is the money going?"
                  defaultValue={receivingLedgerLabel}
                  fullWidth
                  required
                  search={api.searchLedgers}
                  onValueSelect={(o) => setReceivingLedgerId(o?.id || 0)}
                />
              </>
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

function useLedgers({ search, onSetLedgers }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const {
    state: ledgers,
    loading: ledgersLoading,
    asyncFetch: ledgersFetch,
  } = useAsyncFetch(search, {
    default: null,
    pickData: true,
    doNotFetchOnInit: true,
  });

  const initializeToReceivingLedger = React.useCallback(
    (id) => {
      return ledgersFetch({ id })
        .then((ledgers) => {
          return onSetLedgers(ledgers);
        })
        .catch((e) => enqueueErrorSnackbar(e));
    },
    [enqueueErrorSnackbar, ledgersFetch, onSetLedgers]
  );

  const value = React.useMemo(
    () => ({
      ledgers,
      ledgersLoading,
      initializeToReceivingLedger,
    }),
    [ledgers, ledgersLoading, initializeToReceivingLedger]
  );
  return value;
}
