import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import ResourceEdit from "../components/ResourceEdit";
import { dayjs } from "../modules/dayConfig";
import formHelpers from "../modules/formHelpers";
import OfferingForm from "./OfferingForm";
import React from "react";

export default function OfferingEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getCommerceOffering}
      apiUpdate={api.updateCommerceOffering}
      Form={OfferingForm}
    />
  );
}
