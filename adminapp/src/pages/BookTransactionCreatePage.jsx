import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import VendorServiceCategorySelect from "../components/VendorServiceCategorySelect";
import config from "../config";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import formHelpers from "../modules/formHelpers";
import useMountEffect from "../shared/react/useMountEffect";
import { FormLabel, Stack } from "@mui/material";
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
  const [memo, setMemo] = React.useState(formHelpers.initialTranslation);
  const [category, setCategory] = React.useState(null);
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  useMountEffect(() => {
    // If the ID is 0, set the ledger by the platform category.
    // If the ID is > 0, it should be set with an ID lookup from the backend.
    const originatingLedgerId = Number(searchParams.get("originatingLedgerId") || -1);
    const receivingLedgerId = Number(searchParams.get("receivingLedgerId") || -1);
    const categorySlug = searchParams.get("vendorServiceCategorySlug");
    if (originatingLedgerId === -1 && receivingLedgerId === -1 && !categorySlug) {
      // No params are in the URL so we don't search
      return;
    }
    api
      .searchLedgersLookup({
        ids: [originatingLedgerId, receivingLedgerId].filter((x) => x > 0),
        platformCategories: [categorySlug].filter(Boolean),
      })
      .then((r) => {
        const { byId, platformByCategory } = r.data;
        if (originatingLedgerId === 0) {
          setOriginatingLedger(platformByCategory[humps.camelize(categorySlug)]);
        } else if (originatingLedgerId > 0) {
          setOriginatingLedger(byId[originatingLedgerId]);
        }
        if (receivingLedgerId === 0) {
          setReceivingLedger(platformByCategory[humps.camelize(categorySlug)]);
        } else if (receivingLedgerId > 0) {
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
        vendorServiceCategorySlug: category?.slug,
      })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  }
  return (
    <FormLayout
      title="Create a Book Transaction"
      subtitle="Book transactions move virtual money from one ledger to another. They do NOT add
        funds onto the platform."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ResponsiveStack>
          <AutocompleteSearch
            {...register("originatingLedger")}
            label="Originating Ledger"
            helperText="Where is the money coming from?"
            value={originatingLedger?.label}
            fullWidth
            required
            search={api.searchLedgers}
            disabled={Boolean(searchParams.get("originatingLedgerId"))}
            title={originatingLedger?.label}
            style={{ flex: 1 }}
            onValueSelect={(o) => setOriginatingLedger(o)}
          />
          <AutocompleteSearch
            {...register("receivingLedger")}
            label="Receiving Ledger"
            helperText="Where is the money going?"
            value={receivingLedger?.label}
            fullWidth
            required
            search={api.searchLedgers}
            disabled={Boolean(searchParams.get("receivingLedgerId"))}
            title={receivingLedger?.label}
            style={{ flex: 1 }}
            onValueSelect={(o) => setReceivingLedger(o)}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <CurrencyTextField
            {...register("amount")}
            label="Amount"
            helperText="How much is going from originator to receiver?"
            money={amount}
            required
            autoFocus
            style={{ flex: 1 }}
            onMoneyChange={setAmount}
          />
          <VendorServiceCategorySelect
            {...register("category")}
            defaultValue={searchParams.get("vendorServiceCategorySlug")}
            label="Category"
            helperText="What can this be used for?"
            value={category?.slug || ""}
            disabled={Boolean(searchParams.get("vendorServiceCategorySlug"))}
            title={category?.label}
            style={{ flex: 1 }}
            onChange={(_, categoryObj) => setCategory(categoryObj)}
          />
        </ResponsiveStack>
        <FormLabel>Memo (appears on the ledger):</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("memo")}
            label="Memo"
            fullWidth
            value={memo}
            required
            search
            searchParams={{ types: ["memo"] }}
            onChange={(memo) => setMemo(memo)}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
