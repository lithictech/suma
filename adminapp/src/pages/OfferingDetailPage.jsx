import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import Link from "../components/Link";
import Programs from "../components/Programs";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import SumaImage from "../components/SumaImage";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import oneLineAddress from "../modules/oneLineAddress";
import createRelativeUrl from "../shared/createRelativeUrl";
import Money from "../shared/react/Money";
import ListAltIcon from "@mui/icons-material/ListAlt";
import { makeStyles } from "@mui/styles";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function OfferingDetailPage() {
  const classes = useStyles();
  return (
    <ResourceDetail
      resource="offering"
      apiGet={api.getCommerceOffering}
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
        { label: "Opening Date", value: dayjs(model.periodBegin) },
        { label: "Closing Date", value: dayjs(model.periodEnd) },
        {
          label: "Begin Fulfillment At",
          value: model.beginFulfillmentAt && dayjs(model.beginFulfillmentAt),
        },
        { label: "Description (En)", value: model.description.en },
        { label: "Description (Es)", value: model.description.es },
        { label: "Fulfillment Prompt (En)", value: model.fulfillmentPrompt.en },
        { label: "Fulfillment Prompt (Es)", value: model.fulfillmentPrompt.es },
        {
          label: "Fulfillment Instructions (En)",
          value: model.fulfillmentInstructions.en,
        },
        {
          label: "Fulfillment Instructions (Es)",
          value: model.fulfillmentInstructions.es,
        },
        {
          label: "Fulfillment Confirmation (En)",
          value: model.fulfillmentConfirmation.en,
        },
        {
          label: "Fulfillment Confirmation (Es)",
          value: model.fulfillmentConfirmation.es,
        },
        {
          label: "Max ordered items, cumulative",
          value: model.maxOrderedItemsCumulative || "-",
        },
        {
          label: "Max ordered items, per-member",
          value: model.maxOrderedItemsPerMember || "-",
        },
        {
          label: "Pick/Pack list",
          value: !isEmpty(model.orders) ? (
            <Link to={`/offering/${model.id}/picklist`}>
              <ListAltIcon sx={{ verticalAlign: "middle", marginRight: "5px" }} />
              Pick/Pack List
            </Link>
          ) : (
            "-"
          ),
        },
      ]}
    >
      {(model, setModel) => [
        <RelatedList
          title="Fulfillment Options"
          rows={model.fulfillmentOptions}
          headers={["Id", "Description", "Type", "Address"]}
          keyRowAttr="id"
          toCells={(row) => [
            row.id,
            row.description.en,
            row.type,
            row.address && oneLineAddress(row.address, false),
          ]}
        />,
        <Programs
          resource="offering"
          programs={model.programs}
          modelId={model.id}
          replaceModelData={setModel}
          makeUpdateRequest={api.updateOfferingPrograms}
        />,
        <RelatedList
          title={`Offering Products (${model.offeringProducts.length})`}
          addNewLabel="Create Offering Product"
          addNewLink={createRelativeUrl("/offering-product/new", {
            offeringId: model.id,
            offeringLabel: model.description.en,
          })}
          addNewRole="offering_product"
          rows={model.offeringProducts}
          headers={["Id", "Name", "Vendor", "Customer Price", "Full Price"]}
          keyRowAttr="id"
          rowClass={(row) => (row.closedAt ? classes.closed : "")}
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="id" model={row}>
              {row.productName}
            </AdminLink>,
            row.vendorName,
            <Money key="customer_price">{row.customerPrice}</Money>,
            <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
          ]}
        />,
        <RelatedList
          title={`Orders (${model.orders.length})`}
          rows={model.orders}
          headers={["Id", "Created", "Member", "Items", "Status"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            formatDate(row.createdAt),
            <AdminLink key="mem" model={row.member}>
              {row.member.name}
            </AdminLink>,
            row.totalItemCount,
            row.statusLabel,
          ]}
        />,
        <AuditActivityList activities={model.auditActivities} />,
      ]}
    </ResourceDetail>
  );
}

const useStyles = makeStyles(() => ({
  closed: {
    opacity: 0.5,
  },
}));
