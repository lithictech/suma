import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import theme from "../theme";
import map from "lodash/map";
import React from "react";

export default function VendorDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getVendor}
      title={(model) => `Vendor ${model.id}`}
      toEdit={(model) => `/vendor/${model.id}/edit`}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Name", value: model.name },
        { label: "Slug", value: model.slug },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title="Services"
            rows={model.services}
            headers={["Id", "Name", "Eligibility Constraints"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              row.name,
              row.eligibilityConstraints.map((ec) => (
                <AdminLink
                  key={ec.name}
                  model={ec}
                  sx={{ marginRight: theme.spacing(1) }}
                >
                  {ec.name}
                </AdminLink>
              )),
            ]}
          />
          <RelatedList
            title="Products"
            rows={model.products}
            headers={["Id", "Created", "Name"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.name,
              map(row.eligibilityConstraints, "name"),
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
