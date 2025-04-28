import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import SumaImage from "../components/SumaImage";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import React from "react";

export default function VendorDetailPage() {
  return (
    <ResourceDetail
      resource="vendor"
      apiGet={api.getVendor}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Image",
          value: (
            <SumaImage
              image={model.image}
              alt={model.image.name}
              className="w-100"
              params={{ crop: "none" }}
              h={60}
            />
          ),
        },
        { label: "Name", value: model.name },
        { label: "Slug", value: model.slug },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Services"
          rows={model.services}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row}>{row.name}</AdminLink>,
          ]}
        />,
        <RelatedList
          title="Configuration"
          rows={model.configurations}
          headers={["Id", "Vendor", "Auth to Vendor", "Enabled?"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            row.vendor.name,
            row.authToVendorKey,
            <BoolCheckmark>{row.enabled}</BoolCheckmark>,
          ]}
        />,
        <RelatedList
          title="Products"
          rows={model.products}
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
