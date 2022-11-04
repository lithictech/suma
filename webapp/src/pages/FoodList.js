import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import ErrorScreen from "../components/ErrorScreen";
import FoodCart from "../components/FoodCart";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import { t, mdp } from "../localization";
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
  const cartStartElement = (
    <h5 className="m-0">{products && products[0].offeringDescription}</h5>
  );
  return (
    <>
      <Helmet>
        <title>{titleParts.join(" | ")}</title>
      </Helmet>
      <FoodCart startElement={cartStartElement} />
      <img src={foodImage} alt={t("food:title")} className="thin-header-image" />
      <LayoutContainer className="pt-2">
        {productsLoading && <PageLoader />}
        {!productsLoading && (
          <>
            {_.isEmpty(products) && mdp("food:no_products_md")}
            {!_.isEmpty(products) && (
              <Row>
                <LinearBreadcrumbs back />
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
  isDiscounted,
  undiscountedPrice,
  customerPrice,
  image,
}) {
  // isDiscounted = false;
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
          <Money className={clsx("me-2", isDiscounted && "text-success")}>
            {customerPrice}
          </Money>
          {isDiscounted && (
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
