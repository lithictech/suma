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
  const { id } = useParams();
  const getFoodOfferingProducts = React.useCallback(() => {
    return api.getFoodOfferingProducts({ offeringId: id });
  }, [id]);
  const {
    state: offeringProducts,
    loading: productsLoading,
    error: productsError,
  } = useAsyncFetch(getFoodOfferingProducts, {
    default: {},
    pickData: true,
  });
  const products = offeringProducts.items;
  if (productsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  // All products are from the same offering
  // we get +offeringDescription+ from the first occurrence
  const firstProduct = _.first(products);
  const offeringDescription = firstProduct
    ? firstProduct.offeringDescription + " | "
    : "";
  const title = offeringDescription + t("food:title") + " | " + t("titles:suma_app");
  return (
    <>
      {products && (
        <Helmet>
          <title>{title}</title>
        </Helmet>
      )}
      <img src={foodImage} alt="food" className="thin-header-image" />
      <LayoutContainer className="pt-2">
        {productsLoading && <PageLoader />}
        {!_.isEmpty(products) && (
          <Row>
            <LinearBreadcrumbs back />
            <h5 className="mb-4">{firstProduct.offeringDescription}</h5>
            {products.map((p) => (
              <Product key={p.id} offeringId={id} {...p} />
            ))}
          </Row>
        )}
        {_.isEmpty(products) && !productsLoading && (
          <p>
            There were no products found, this offering might be closed.{" "}
            <Link to="/food">Click here to view available offerings</Link>
          </p>
        )}
      </LayoutContainer>
    </>
  );
}

function Product({ id, offeringId, name, undiscountedPrice, customerPrice }) {
  return (
    <Col xs={6} key={id} className="mb-2">
      <div className="position-relative">
        {/* TODO: refactor image src with correct link */}
        <img src="/temporary-food-chicken.jpg" alt={name} className="w-100" />
        <div className="food-widget-container position-absolute">
          <FoodWidget productId={id} />
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
        <Link to={`/product/${offeringId}-${id}`} className="stretched-link" />
      </div>
    </Col>
  );
}
