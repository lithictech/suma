import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import ErrorScreen from "../components/ErrorScreen";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Helmet } from "react-helmet-async";
import { Link, useParams } from "react-router-dom";

export default function FoodList() {
  const { id: offeringId } = useParams();
  const getFoodOfferingProducts = React.useCallback(() => {
    return api.getFoodOfferingProducts({ offeringId });
  }, [offeringId]);
  const {
    state: offeringProducts,
    loading: productsLoading,
    error: productsError,
  } = useAsyncFetch(getFoodOfferingProducts, {
    default: {},
    pickData: true,
  });
  if (productsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const products = offeringProducts.items;
  // All products are from the same offering
  // we get +offeringDescription+ from the first occurrence
  const titleParts = [t("food:title"), t("titles:suma_app")];
  if (products?.length > 0) {
    titleParts.unshift(products[0].offeringDescription);
  }
  return (
    <>
      <Helmet>
        <title>{titleParts.join(" | ")}</title>
      </Helmet>
      <img src={foodImage} alt="food" className="thin-header-image" />
      <LayoutContainer className="pt-2">
        {productsLoading && <PageLoader />}
        {!productsLoading && (
          <>
            {_.isEmpty(products) && (
              <p>
                There were no products found, this offering might be closed.{" "}
                <Link to="/food">Click here to view available offerings</Link>
              </p>
            )}
            {!_.isEmpty(products) && (
              <Row>
                <LinearBreadcrumbs back />
                <h5 className="mb-4">{products[0].offeringDescription}</h5>
                {products.map((p) => (
                  <Product key={p.productId} offeringId={offeringId} {...p} />
                ))}
              </Row>
            )}
          </>
        )}
      </LayoutContainer>
    </>
  );
}

function Product({
  productId,
  offeringId,
  name,
  undiscountedPrice,
  customerPrice,
  image,
}) {
  const url = `${image.url}?w=225&h=150`;
  return (
    <Col xs={6} className="mb-2">
      <div className="position-relative">
        <img src={url} alt={name} className="w-100" />
        <div className="food-widget-container position-absolute">
          <FoodWidget productId={productId} />
        </div>
        <h6 className="mb-0 mt-2">{name}</h6>
        <p className="mb-0 fs-5 fw-semibold">
          <Money className={clsx("me-2", customerPrice && "text-success")}>
            {customerPrice || undiscountedPrice}
          </Money>
          {customerPrice && (
            <strike>
              <Money>{undiscountedPrice}</Money>
            </strike>
          )}
        </p>
        <Link to={`/product/${offeringId}-${productId}`} className="stretched-link" />
      </div>
    </Col>
  );
}
