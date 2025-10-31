import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function VendorServiceCategoryDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_service_category"
      apiGet={api.getVendorServiceCategory}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Name", value: model.name },
        { label: "Slug", value: model.slug },
        {
          label: "Parent",
          value: <AdminLink model={model.parent}>{model.parent?.name}</AdminLink>,
        },
      ]}
    />
  );
}
