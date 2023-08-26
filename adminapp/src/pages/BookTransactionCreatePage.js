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
import { Stack, Typography } from "@mui/material";
import Box from "@mui/material/Box";
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
  const [memo, setMemo] = React.useState({ en: "" });
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
        platformCategories: [categorySlug],
      })
      .then((r) => {
        const { byId, platformByCategory } = r.data;
        if (originatingLedgerId === 0) {
          setOriginatingLedger(platformByCategory[categorySlug]);
        } else if (originatingLedgerId) {
          setOriginatingLedger(byId[originatingLedgerId]);
        }
        if (receivingLedgerId === 0) {
          setReceivingLedger(platformByCategory[categorySlug]);
        } else if (receivingLedgerId) {
          setReceivingLedger(byId[receivingLedgerId]);
        }
      })
      .catch(enqueueErrorSnackbar);
  }, [searchParams, enqueueErrorSnackbar]);

  function submit() {
    console.log(memo);
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
              sx={{ maxWidth: "130px" }}
              helperText="How much is going from originator to receiver?"
              money={amount}
              required
              onMoneyChange={setAmount}
            />
            <div>
              <VendorServiceCategorySelect
                {...register("category")}
                defaultValue={searchParams.get("vendorServiceCategorySlug")}
                label="Category"
                sx={{ maxWidth: "200px" }}
                helperText="What can this be used for?"
                value={category}
                onChange={(categorySlug) => setCategory(categorySlug)}
              />
            </div>
            <MultiLingualText
              {...register("memo")}
              label="Memo"
              helperText="This shows on the ledger."
              fullWidth
              value={memo}
              sx={{ minWidth: "300px" }}
              required
              onChange={(memo) => setMemo(memo)}
            />
          </Stack>
          <Stack direction="row" spacing={2}>
            <AutocompleteSearch
              {...register("originatingLedger")}
              label="Originating Ledger"
              helperText="Where is the money coming from?"
              defaultValue={originatingLedger?.label}
              fullWidth
              required
              search={api.searchLedgers}
              onValueSelect={(o) => setOriginatingLedger(o)}
            />
            <AutocompleteSearch
              {...register("receivingLedger")}
              label="Receiving Ledger"
              helperText="Where is the money going?"
              defaultValue={receivingLedger?.label}
              fullWidth
              required
              search={api.searchLedgers}
              onValueSelect={(o) => setReceivingLedger(o)}
            />
          </Stack>
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
