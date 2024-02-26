import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import PaymentTriggerForm from "./PaymentTriggerForm";
import dayjs from "dayjs";
import React from "react";

export default function PaymentTriggerCreatePage() {
  const empty = {
    label: "",
    description: formHelpers.initialTranslation,
    fulfillmentPrompt: formHelpers.initialTranslation,
    fulfillmentConfirmation: formHelpers.initialTranslation,
    fulfillmentOptions: [formHelpers.initialFulfillmentOption],
    activeDuringBegin: dayjs().format(),
    activeDuringEnd: dayjs().add(1, "day").format(),
    matchMultiplier: 1,
    maximumCumulativeSubsidyCents: 100_00,
  };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createPaymentTrigger}
      Form={PaymentTriggerForm}
    />
  );
}
