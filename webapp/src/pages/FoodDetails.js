import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import React from "react";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import { useParams } from "react-router-dom";

export default function FoodDetails() {
  const { offeringId, productId } = useParams();
  const getFoodProduct = React.useCallback(() => {
    return api.getFoodProduct({ offeringId, productId });
  }, [offeringId, productId]);
  const {
    state: product,
    loading: productLoading,
    error: productError,
  } = useAsyncFetch(getFoodProduct, {
    default: {},
    pickData: true,
  });
  if (productError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (productLoading) {
    return <PageLoader />;
  }
  const title = [
    product.name,
    product.vendor.name,
    t("food:title"),
    t("titles:suma_app"),
  ].join(" | ");
  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <LayoutContainer className="pt-2">
        <LinearBreadcrumbs back />
      </LayoutContainer>
      <img
        src={product.images[0].url + "?w=500&h=325"}
        alt={product.name}
        className="w-100"
      />
      <LayoutContainer top>
        <h3 className="mb-2">{product.name}</h3>
        <Stack direction="horizontal">
          <div>
            <p className="mb-0 fs-4">
              <Money className={clsx("me-2", product.isDiscounted && "text-success")}>
                {product.customerPrice}
              </Money>
              {product.isDiscounted && (
                <strike>
                  <Money>{product.undiscountedPrice}</Money>
                </strike>
              )}
            </p>
            <p>{t("food:from") + " " + product.vendor.name}</p>
          </div>
          <div className="ms-auto">
            <FoodWidget {...product} large={true} />
          </div>
        </Stack>
        <hr />
        <h5 className="mt-2 mb-2">{t("food:details_header")}</h5>
        <p>{product.description}</p>
      </LayoutContainer>
    </>
  );
}
