import api from "../api";
import AdminLink from "../components/AdminLink";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useRoleAccess from "../hooks/useRoleAccess";
import { dayjs } from "../modules/dayConfig";
import createRelativeUrl from "../shared/createRelativeUrl";
import Money from "../shared/react/Money";
import SumaImage from "../shared/react/SumaImage";
import ListAltIcon from "@mui/icons-material/ListAlt";
import React from "react";

export default function ProductDetailPage() {
  const { canWriteResource } = useRoleAccess();
  return (
    <ResourceDetail
      resource="product"
      apiGet={api.getCommerceProduct}
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
        { label: "Name (En)", value: model.name.en },
        { label: "Name (Es)", value: model.name.es },
        { label: "Description (En)", value: model.description.en },
        { label: "Description (Es)", value: model.description.es },
        {
          label: "Vendor",
          value: <AdminLink model={model.vendor}>{model.vendor.name}</AdminLink>,
        },
        {
          label: "Category",
          value: model.vendorServiceCategories[0]?.name,
        },
        { label: "Our Cost", value: <Money>{model.ourCost}</Money> },
        {
          label: "Max Per Member/Offering",
          value: model.inventory.maxQuantityPerMemberPerOffering,
        },
        { label: "Limited Quantity", value: model.inventory.limitedQuantity },
        { label: "Quantity On Hand", value: model.inventory.quantityOnHand },
        {
          label: "Quantity Pending Fulfillment",
          value: model.inventory.quantityPendingFulfillment,
        },
        canWriteResource("offering_product") && {
          label: "Create Offering Product",
          value: (
            <Link
              to={createRelativeUrl(`/offering-product/new`, {
                productId: model.id,
                productLabel: model.name.en,
              })}
            >
              <ListAltIcon sx={{ verticalAlign: "middle", marginRight: "5px" }} />
              Create Offering Product
            </Link>
          ),
        },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title={`Offering Products`}
            rows={model.offeringProducts}
            headers={["Id", "Customer Price", "Full Price", "Offering", "Closed"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key={row.id} model={row}>
                {row.id}
              </AdminLink>,
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
              <AdminLink key="offering" model={row.offering}>
                {row.offering.description.en}
              </AdminLink>,
              row.isClosed ? dayjs(row.closedAt).format("lll") : "",
            ]}
          />
          <RelatedList
            title="Orders"
            rows={model.orders}
            headers={["Id", "Created At", "Status", "Member"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.orderStatus,
              <AdminLink key="member" model={row.member}>
                {row.member.name}
              </AdminLink>,
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
