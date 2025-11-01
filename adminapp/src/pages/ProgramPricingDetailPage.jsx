import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function ProgramPricingDetailPage() {
  return (
    <ResourceDetail
      resource="program_pricing"
      canEdit={true}
      backTo={(m) => m.program?.adminLink}
      apiGet={api.getProgramPricing}
      apiDelete={api.destroyProgramPricing}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        {
          label: "Program",
          value: <AdminLink model={model.program}>{model.program.name.en}</AdminLink>,
        },
        {
          label: "Vendor Service",
          value: (
            <AdminLink model={model.vendorService}>
              {model.vendorService.internalName}
            </AdminLink>
          ),
        },
        {
          label: "Rate",
          value: (
            <AdminLink model={model.vendorServiceRate}>
              {model.vendorServiceRate.internalName}
            </AdminLink>
          ),
        },
      ]}
    />
  );
}
