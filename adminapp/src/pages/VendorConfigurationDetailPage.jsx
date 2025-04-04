import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import BoolCheckmark from "../components/BoolCheckmark";
import Programs from "../components/Programs";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function VendorConfigurationDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_configuration"
      apiGet={api.getVendorConfiguration}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Vendor",
          value: <AdminLink model={model.vendor}>{model.vendor.name}</AdminLink>,
        },
        {
          label: "App Install Link",
          value: (
            <SafeExternalLink href={model.appInstallLink}>
              {model.appInstallLink}
            </SafeExternalLink>
          ),
        },
        { label: "Auth-to-Vendor", value: model.authToVendorKey },
        { label: "Enabled", value: <BoolCheckmark>{model.enabled}</BoolCheckmark> },
        { label: "Instructions (En)", value: model.instructions.en },
        { label: "Instructions (Es)", value: model.instructions.es },
        {
          label: "Linked Success Instructions (En)",
          value: model.linkedSuccessInstructions.en,
        },
        {
          label: "Linked Success Instructions (Es)",
          value: model.linkedSuccessInstructions.es,
        },
      ]}
    >
      {(model, setModel) => (
        <>
          <Programs
            resource="vendor_configuration"
            programs={model.programs}
            modelId={model.id}
            replaceModelData={setModel}
            makeUpdateRequest={api.updateVendorConfigurationPrograms}
          />
          <AuditActivityList activities={model.auditActivities} />
        </>
      )}
    </ResourceDetail>
  );
}
