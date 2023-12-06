import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function EligibilityConstraintDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getEligibilityConstraint}
      title={(model) => `Eligibility Constraint ${model.id}`}
      toEdit={(model) => `/constraint/${model.id}/edit`}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Name", value: model.name },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title="Offerings"
            rows={model.offerings}
            keyRowAttr="id"
            headers={["Id", "Created", "Description", "Opens", "Closes"]}
            toCells={(row) => [
              <AdminLink key={row.id} model={row}>
                {row.id}
              </AdminLink>,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.id} model={row}>
                {row.description.en}
              </AdminLink>,
              dayjs(row.opensAt).format("lll"),
              dayjs(row.closesAt).format("lll"),
            ]}
          />
          <RelatedList
            title="Vendor Services"
            rows={model.services}
            keyRowAttr="id"
            headers={["Id", "Created", "Vendor", "Name"]}
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.id} model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              row.name,
            ]}
          />
          <RelatedList
            title="Vendor Configurations"
            rows={model.configurations}
            keyRowAttr="id"
            headers={[
              "Id",
              "Created",
              "Vendor",
              "App Install Link",
              "Uses Email",
              "Uses SMS",
              "Enabled",
            ]}
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.vendor.name} model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              <SafeExternalLink key={1} href={row.appInstallLink}>
                {row.appInstallLink}
              </SafeExternalLink>,
              row.usesEmail ? "Yes" : "No",
              row.usesSms ? "Yes" : "No",
              row.enabled ? "Yes" : "No",
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
