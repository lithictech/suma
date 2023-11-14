import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function OfferingProductDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceOfferingProduct = React.useCallback(() => {
    return api.getCommerceOfferingProduct({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: offeringProduct, loading: offeringProductLoading } = useAsyncFetch(
    getCommerceOfferingProduct,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <>
      {offeringProductLoading && <CircularProgress />}
      {!isEmpty(offeringProduct) && (
        <div>
          <DetailGrid
            title={`Offering Product ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(offeringProduct.createdAt) },
              {
                label: "Offering",
                value: (
                  <AdminLink
                    key={offeringProduct.offering.id}
                    model={offeringProduct.offering}
                  >
                    {offeringProduct.offering.description}
                  </AdminLink>
                ),
              },
              {
                label: "Product",
                value: (
                  <AdminLink
                    key={offeringProduct.product.id}
                    model={offeringProduct.product}
                  >
                    {offeringProduct.product.name}
                  </AdminLink>
                ),
              },
              {
                label: "Customer Price",
                value: <Money>{offeringProduct.customerPrice}</Money>,
              },
              {
                label: "Undiscounted Price",
                value: <Money>{offeringProduct.undiscountedPrice}</Money>,
              },
              {
                label: "Closed",
                value: offeringProduct.closedAt ? dayjs(offeringProduct.closedAt) : "",
              },
            ]}
          />
        </div>
      )}
    </>
  );
}
