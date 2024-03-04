import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import PaymentTriggerForm from "./PaymentTriggerForm";
import React from "react";

export default function PaymentTriggerEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getPaymentTrigger}
      apiUpdate={api.updatePaymentTrigger}
      Form={PaymentTriggerForm}
    />
  );
}
