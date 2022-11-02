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
import { Link, useParams } from "react-router-dom";

export default function FoodDetails() {
  const { offeringId, productId } = useParams();
  const getFoodProduct = React.useCallback(() => {
    return api.getFoodProduct({ offeringId: offeringId, productId: productId });
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
  const subTitle = product.vendor ? product.vendor.name + " | " : t("food:title") + " | ";
  const title = `${product.name} | ${subTitle}${t("titles:suma_app")}`;
  return (
    <>
      {product && (
        <Helmet>
          <title>{title}</title>
        </Helmet>
      )}
      <LayoutContainer className="pt-2">
        <LinearBreadcrumbs back />
      </LayoutContainer>
      {/* TODO: refactor image src with correct link */}
      <img src="/temporary-food-chicken.jpg" alt={product.name} className="w-100" />
      <LayoutContainer top>
        <h3 className="mb-2">{product.name}</h3>
        <Stack direction="horizontal" className="align-items-baseline">
          <div>
            <p className="mb-0 fs-4">
              {/* TODO: Render undiscount_price and customer_price somehow from back-end */}
              <Money className={clsx("me-2", product.customerPrice && "text-success")}>
                {product.customerPrice || product.undiscountedPrice}
              </Money>
              {product.customerPrice && (
                <strike>
                  <Money>{product.undiscountedPrice}</Money>
                </strike>
              )}
            </p>
            <Link to={`/offering/${offeringId}`}>Shop at {product.vendor.name}</Link>
          </div>
          <div className="ms-auto">
            <FoodWidget {...product} large={true} />
          </div>
        </Stack>
        <hr />
        <h5 className="mt-2 mb-2">Details</h5>
        <p>{product.description}</p>
      </LayoutContainer>
    </>
  );
}
