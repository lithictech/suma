import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import config from "../config";
import { dayjs } from "../modules/dayConfig";
import OffPlatformTransactionInputs from "./OffPlatformTransactionInputs";
import { FormControlLabel, Radio, RadioGroup, Stack } from "@mui/material";
import React from "react";

export default function OffPlatformTransactionCreatePage() {
  const empty = {
    type: "funding",
    amount: config.defaultZeroMoney,
    note: "",
    checkOrTransactionNumber: "",
    transactedAt: dayjs().toISOString(),
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOffPlatformTransaction}
      Form={Form}
    />
  );
}

function Form({ resource, setField, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Create an Off Platform Transaction"
      subtitle="Off Platform transactions represent the flow of funds into and out of the platform,
      which cannot be presented in other ways.
      For example, a check from a private funder providing a subsidy would be
      an Off Platform Funding Transaction. Paying an invoice, for example,
      would be an Off Platform Payout Transaction. We should try to represent these transactions
      with on-platform functions where possible; but in many cases, or in historical situations,
      it is not possible."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack gap={2}>
        <RadioGroup
          value={resource.type}
          row
          onChange={(e) => setField("type", e.target.value)}
        >
          <FormControlLabel value="funding" control={<Radio />} label="Funding" />
          <FormControlLabel value="payout" control={<Radio />} label="Payout" />
        </RadioGroup>
        <OffPlatformTransactionInputs
          register={register}
          resource={resource}
          setField={setField}
          setFieldFromInput={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
