import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import PaymentTriggerForm from "./PaymentTriggerForm";
import React from "react";

export default function PaymentTriggerCreatePage() {
  const empty = {
    label: "",
    description: stub.translation,
    receivingLedgerName: "",
    receivingLedgerContributionText: stub.translation,
    memo: stub.translation,
    activeDuring: [],
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
