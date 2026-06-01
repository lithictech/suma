import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import PaymentTriggerForm from "./PaymentTriggerForm";
import dayjs from "dayjs";
import React from "react";

export default function PaymentTriggerCreatePage() {
  const empty = {
    label: "",
    description: stub.translation,
    receivingLedgerName: "",
    receivingLedgerContributionText: stub.translation,
    memo: stub.translation,
    activeDuringBegin: dayjs().format(),
    activeDuringEnd: dayjs().add(1, "day").format(),
    matchMultiplier: 1,
    maximumCumulativeSubsidyCents: 100_00,
    unmatchedAmountCents: 0,
  };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createPaymentTrigger}
      Form={PaymentTriggerForm}
    />
  );
}
