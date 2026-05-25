import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { dayjs } from "../modules/dayConfig";
import { stub } from "../modules/formHelpers";
import OfferingForm from "./OfferingForm";
import React from "react";

export default function OfferingCreatePage() {
  const empty = {
    image: null,
    imageCaption: stub.translation,
    description: stub.translation,
    fulfillmentPrompt: stub.translation,
    fulfillmentConfirmation: stub.translation,
    fulfillmentInstructions: stub.translation,
    fulfillmentOptions: stub.collection,
    periodBegin: dayjs().format(),
    periodEnd: dayjs().add(1, "day").format(),
    beginFulfillmentAt: null,
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
