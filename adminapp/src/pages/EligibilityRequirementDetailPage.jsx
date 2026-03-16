import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import detailPageImageProperties from "../components/detailPageImageProperties";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import EligibilityAttributeCreatePage from "./EligibilityAttributeCreatePage";
import EligibilityRequirementCreatePage from "./EligibilityRequirementCreatePage";
import React from "react";

export default function EligibilityRequirementDetailPage() {
  return (
    <ResourceDetail
      resource="eligibility_requirement"
      apiGet={api.getEligibilityRequirement}
      apiDelete={api.destroyEligibilityRequirement}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        model.createdBy && {
          label: "Created By",
          value: <AdminLink model={model.createdBy}>{model.createdBy.name}</AdminLink>,
        },
        {
          label: "Resource",
          value: (
            <AdminLink model={model.resource}>
              {model.resource.label} ({model.resourceType})
            </AdminLink>
          ),
        },
      ]}
    >
      {(model) => [
        // <RelatedList
        //   title="Services"
        //   rows={model.services}
        //   headers={["Id", "Name"]}
        //   keyRowAttr="id"
        //   toCells={(row) => [
        //     <AdminLink model={row} />,
        //     <AdminLink model={row}>{row.internalName}</AdminLink>,
        //   ]}
        // />,
        // <RelatedList
        //   title="Configuration"
        //   rows={model.configurations}
        //   headers={["Id", "Vendor", "Auth to Vendor", "Enabled?"]}
        //   keyRowAttr="id"
        //   toCells={(row) => [
        //     <AdminLink key="id" model={row} />,
        //     row.vendor.name,
        //     row.authToVendorKey,
        //     <BoolCheckmark>{row.enabled}</BoolCheckmark>,
        //   ]}
        // />,
        // <RelatedList
        //   title="Products"
        //   rows={model.products}
        //   headers={["Id", "Created", "Name"]}
        //   keyRowAttr="id"
        //   toCells={(row) => [
        //     <AdminLink key="id" model={row} />,
        //     formatDate(row.createdAt),
        //     row.name.en,
        //   ]}
        // />,
      ]}
    </ResourceDetail>
  );
}
