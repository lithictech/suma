import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
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
      title={(vendor) => `Vendor ${vendor.id}`}
      properties={(vendor) => [
        { label: "ID", value: vendor.id },
        { label: "Created At", value: dayjs(vendor.createdAt) },
        { label: "Name", value: vendor.name },
        { label: "Slug", value: vendor.slug },
      ]}
      toEdit={(vendor) => `/vendor/${vendor.id}/edit`}
    >
      {(vendor) => (
        <>
          <RelatedList
            title="Services"
            rows={vendor.services}
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
            rows={vendor.products}
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
