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
      canEdit
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
        { label: "Description (En)", value: model.descriptionText.en },
        { label: "Description (Es)", value: model.descriptionText.es },
        { label: "Help (En)", value: model.helpText.en },
        { label: "Help (Es)", value: model.helpText.es },
        { label: "Terms (En)", value: model.termsText.en },
        { label: "Terms (Es)", value: model.termsText.es },
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
      {(model, setModel) => [
        <Programs
          resource="vendor_configuration"
          programs={model.programs}
          modelId={model.id}
          replaceModelData={setModel}
          makeUpdateRequest={api.updateVendorConfigurationPrograms}
        />,
        <AuditActivityList activities={model.auditActivities} />,
      ]}
    </ResourceDetail>
  );
}
