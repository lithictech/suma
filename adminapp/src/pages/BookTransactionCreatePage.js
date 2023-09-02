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

export default function BookTransactionCreatePage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [originatingLedger, setOriginatingLedger] = React.useState(null);
  const [receivingLedger, setReceivingLedger] = React.useState(null);
  const [amount, setAmount] = React.useState(config.defaultZeroMoney);
  const [memo, setMemo] = React.useState({
    en: searchParams.get("memoEn") || "",
    es: searchParams.get("memoEs") || "",
  });
  const [category, setCategory] = React.useState("");
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  useMountEffect(() => {
    const originatingLedgerId = Number(searchParams.get("originatingLedgerId"));
    const receivingLedgerId = Number(searchParams.get("receivingLedgerId"));
    const categorySlug = searchParams.get("vendorServiceCategorySlug");
    if (!originatingLedgerId && !receivingLedgerId) {
      return;
    }
    api
      .searchLedgersLookup({
        ids: [originatingLedgerId, receivingLedgerId],
        platformCategories: [categorySlug].filter(Boolean),
      })
      .then((r) => {
        const { byId, platformByCategory } = r.data;
        if (originatingLedgerId === 0) {
          setOriginatingLedger(platformByCategory[humps.camelize(categorySlug)]);
        } else if (originatingLedgerId) {
          setOriginatingLedger(byId[originatingLedgerId]);
        }
        if (receivingLedgerId === 0) {
          setReceivingLedger(platformByCategory[humps.camelize(categorySlug)]);
        } else if (receivingLedgerId) {
          setReceivingLedger(byId[receivingLedgerId]);
        }
      })
      .catch(enqueueErrorSnackbar);
  }, [searchParams, enqueueErrorSnackbar]);

  function submit() {
    busy();
    api
      .createBookTransaction({
        originatingLedgerId: originatingLedger?.id,
        receivingLedgerId: receivingLedger?.id,
        amount,
        memo,
        vendorServiceCategorySlug: category,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }

  const disableFields = searchParams.size > 0;
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
          <Stack direction="row" spacing={2}>
            <AutocompleteSearch
              {...register("originatingLedger")}
              label="Originating Ledger"
              helperText="Where is the money coming from?"
              defaultValue={originatingLedger?.label}
              disabled={disableFields && Boolean(searchParams.get("originatingLedgerId"))}
              fullWidth
              required
              search={api.searchLedgers}
              style={{ flex: 1 }}
              onValueSelect={(o) => setOriginatingLedger(o)}
            />
            <AutocompleteSearch
              {...register("receivingLedger")}
              label="Receiving Ledger"
              helperText="Where is the money going?"
              defaultValue={receivingLedger?.label}
              disabled={disableFields && Boolean(searchParams.get("receivingLedgerId"))}
              fullWidth
              required
              search={api.searchLedgers}
              style={{ flex: 1 }}
              onValueSelect={(o) => setReceivingLedger(o)}
            />
          </Stack>
          <Stack direction="row" spacing={2}>
            <CurrencyTextField
              {...register("amount")}
              label="Amount"
              helperText="How much is going from originator to receiver?"
              money={amount}
              autoFocus={disableFields}
              required
              style={{ flex: 1 }}
              onMoneyChange={setAmount}
            />
            <VendorServiceCategorySelect
              {...register("category")}
              defaultValue={searchParams.get("vendorServiceCategorySlug")}
              disabled={disableFields}
              label="Category"
              helperText="What can this be used for?"
              value={category}
              style={{ flex: 1 }}
              onChange={(categorySlug) => setCategory(categorySlug)}
            />
          </Stack>
          <FormLabel>Memo (appears on the ledger):</FormLabel>
          <Stack direction="row" spacing={2}>
            <MultiLingualText
              label="Memo"
              fullWidth
              value={memo}
              disabled={disableFields}
              required
              onChange={(memo) => setMemo(memo)}
            />
          </Stack>

          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
