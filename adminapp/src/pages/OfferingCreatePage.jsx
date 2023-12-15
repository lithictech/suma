import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { dayjs } from "../modules/dayConfig";
import formHelpers from "../modules/formHelpers";
import OfferingForm from "./OfferingForm";
import React from "react";

export default function OfferingCreatePage() {
  const empty = {
    image: null,
    description: formHelpers.initialTranslation,
    fulfillmentPrompt: formHelpers.initialTranslation,
    fulfillmentConfirmation: formHelpers.initialTranslation,
    fulfillmentOptions: [formHelpers.initialFulfillmentOption],
    periodBegin: dayjs().format(),
    periodEnd: dayjs().add(1, "day").format(),
    beginFulfillmentAt: null,
    prohibitChargeAtCheckout: false,
    maxOrderedItemsCumulative: null,
    maxOrderedItemsPerMember: null,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createCommerceOffering}
      Form={OfferingForm}
    />
  );
}
