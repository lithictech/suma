import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import detailPageImageProperties from "../components/detailPageImageProperties";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import formatDate from "../modules/formatDate";
import React from "react";

export default function VendorDetailPage() {
  return (
    <ResourceDetail
      resource="vendor"
      apiGet={api.getVendor}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        { label: "Name", value: model.name },
        { label: "Slug", value: model.slug },
        ...detailPageImageProperties(model.image),
      ]}
    >
      {(model) => [
        <RelatedListRemote
          title="Services"
          collection={model.services}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row}>{row.internalName}</AdminLink>,
          ]}
        />,
        <RelatedListRemote
          title="Configuration"
          collection={model.configurations}
          headers={["Id", "Vendor", "Auth to Vendor", "Enabled?"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            row.vendor.name,
            row.authToVendorKey,
            <BoolCheckmark>{row.enabled}</BoolCheckmark>,
          ]}
        />,
        <RelatedListRemote
          title="Products"
          collection={model.products}
          headers={["Id", "Created", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            formatDate(row.createdAt),
            row.name.en,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
