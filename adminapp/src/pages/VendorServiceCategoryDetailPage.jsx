import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import React from "react";

export default function VendorServiceCategoryDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_service_category"
      apiGet={api.getVendorServiceCategory}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        { label: "Name", value: model.name },
        { label: "Slug", value: model.slug },
        {
          label: "Parent",
          value: <AdminLink model={model.parent}>{model.parent?.name}</AdminLink>,
        },
      ]}
    >
      {(model) => [
        <RelatedListRemote
          title="Children"
          collection={model.children}
          headers={["Id", "Name", "Slug"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row}>{row.id}</AdminLink>,
            <AdminLink model={row.name}>{row.name}</AdminLink>,
            <AdminLink model={row.slug}>{row.slug}</AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
