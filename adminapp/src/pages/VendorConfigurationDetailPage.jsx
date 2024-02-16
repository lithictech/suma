import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import EligibilityConstraints from "../components/EligibilityConstraints";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function VendorConfigurationDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getVendorConfiguration}
      title={(model) => `Vendor Configuration ${model.id}`}
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
        { label: "Uses SMS?", value: <BoolCheckmark>{model.usesSms}</BoolCheckmark> },
        { label: "Uses Email?", value: <BoolCheckmark>{model.usesEmail}</BoolCheckmark> },
        { label: "Enabled?", value: <BoolCheckmark>{model.enabled}</BoolCheckmark> },
      ]}
    >
      {(model, setModel) => (
        <>
          <EligibilityConstraints
            constraints={model.eligibilityConstraints}
            modelId={model.id}
            replaceModelData={setModel}
            makeUpdateRequest={api.updateVendorConfigurationEligibilityConstraints}
          />
        </>
      )}
    </ResourceDetail>
  );
}
