import api from "../api";
import AdminLink from "../components/AdminLink";
import Programs from "../components/Programs";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import SumaImage from "../components/SumaImage";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function VendorServiceDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_service"
      apiGet={api.getVendorService}
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
              h={150}
            />
          ),
        },
        { label: "Name", value: model.name },
        { label: "Internal Name", value: model.internalName },
        { label: "Mobility Vendor Adapter Key", value: model.mobilityVendorAdapterKey },
        {
          label: "Vendor",
          value: <AdminLink model={model.vendor}>{model.vendor?.name}</AdminLink>,
        },
        { label: "Opening Date", value: dayjs(model.periodBegin) },
        { label: "Closing Date", value: dayjs(model.periodEnd) },
      ]}
    >
      {(model, setModel) => (
        <>
          <Programs
            resource="vendor_service"
            modelId={model.id}
            programs={model.programs}
            makeUpdateRequest={api.updateVendorServicePrograms}
            replaceModelData={setModel}
          />
          <RelatedList
            title="Categories"
            rows={model.categories}
            headers={["Id", "Name", "Slug"]}
            keyRowAttr="id"
            toCells={(row) => [row.id, row.name, row.slug]}
          />
          <RelatedList
            title="Rates"
            rows={model.rates}
            headers={[
              "Id",
              "Created",
              "Name",
              "Unit Amount",
              "Surcharge",
              "Unit Offset",
              "Undiscounted Amount",
              "Undiscounted Surcharge",
            ]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              row.name,
              <Money key="unit_amount">{row.unitAmount}</Money>,
              <Money key="surcharge">{row.surcharge}</Money>,
              row.unitOffset,
              <Money key="undiscounted_amount">{row.undiscountedAmount}</Money>,
              <Money key="undiscounted_surcharge">{row.undiscountedSurcharge}</Money>,
            ]}
          />
          <RelatedList
            title="Mobility Trips"
            rows={model.mobilityTrips}
            headers={[
              "Id",
              "Created",
              "Vehicle Id",
              "Rate",
              "Began",
              "Ended",
              "Begin Latitude",
              "Begin Longitude",
              "Ending Latitude",
              "Ending Longitude",
              "Total Cost",
              "Discount Amount",
            ]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              row.vehicleId,
              row.rate.name,
              // This formatting shows date and time with seconds
              dayjs(row.beganAt).format("ll LTS"),
              dayjs(row.endedAt).format("ll LTS"),
              row.beginLat,
              row.beginLng,
              row.endLat,
              row.endLng,
              <Money>{row.totalCost}</Money>,
              <Money>{row.discountAmount}</Money>,
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
