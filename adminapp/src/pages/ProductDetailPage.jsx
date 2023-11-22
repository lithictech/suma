import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import SumaImage from "../shared/react/SumaImage";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import EditIcon from "@mui/icons-material/Edit";
import ListAltIcon from "@mui/icons-material/ListAlt";
import { CircularProgress } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function ProductDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceProduct = React.useCallback(() => {
    return api.getCommerceProduct({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: product, loading: productLoading } = useAsyncFetch(getCommerceProduct, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {productLoading && <CircularProgress />}
      {!isEmpty(product) && (
        <div>
          <DetailGrid
            title={
              <>
                Product {id}
                <IconButton href={`/product/${id}/edit`}>
                  <EditIcon color="info" />
                </IconButton>
              </>
            }
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(product.createdAt) },
              {
                label: "Image",
                value: (
                  <SumaImage
                    image={product.image}
                    alt={product.image.name}
                    className="w-100"
                    params={{ crop: "center" }}
                    h={225}
                    width={225}
                  />
                ),
              },
              { label: "Name (En)", value: product.name.en },
              { label: "Name (Es)", value: product.name.es },
              { label: "Description (En)", value: product.description.en },
              { label: "Description (Es)", value: product.description.es },
              {
                label: "Vendor",
                value: (
                  <AdminLink model={product.vendor}>{product.vendor.name}</AdminLink>
                ),
              },
              { label: "Our Cost", value: <Money>{product.ourCost}</Money> },
              { label: "Max Per Offering", value: product.maxQuantityPerOffering },
              { label: "Max Per Order", value: product.maxQuantityPerOrder },
            ]}
          />
          <RelatedList
            title="Orders"
            rows={product.orders}
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
          <RelatedList
            title={`Offering Products`}
            rows={product.offeringProducts}
            headers={["Id", "Customer Price", "Full Price", "Offering", "Closed"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key={row.id} model={row}>
                {row.id}
              </AdminLink>,
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
              <AdminLink key="offering" model={row.offering}>
                {row.offering.description}
              </AdminLink>,
              row.isClosed ? dayjs(row.closedAt).format("lll") : "",
            ]}
          />
          <Link
            to={`/offering-product/new?productId=${product.id}&productName=${product.name.en}`}
            sx={{ display: "inline-block", marginTop: "15px" }}
          >
            <ListAltIcon sx={{ verticalAlign: "middle", paddingRight: "5px" }} />
            Create Offering Product
          </Link>
        </div>
      )}
    </>
  );
}
