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
  const { offeringId } = useParams();
  const getFoodOfferingProducts = React.useCallback(() => {
    return api.getFoodOfferingProducts({ offeringId: offeringId || null });
  }, [offeringId]);
  const {
    state: offeringProducts,
    loading: productsLoading,
    error: productsError,
  } = useAsyncFetch(getFoodOfferingProducts, {
    pickData: true,
  });
  const products = offeringProducts?.items;
  if ((_.isEmpty(products) || productsError) && !productsLoading) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const firstProduct = _.first(products);
  const productsVendorName = firstProduct
    ? firstProduct.vendor.name + " | "
    : t("food:title") + " | ";
  const title = productsVendorName + t("titles:suma_app");
  return (
    <>
      {products && (
        <Helmet>
          <title>{title}</title>
        </Helmet>
      )}
      <img src={foodImage} alt="food" className="thin-header-image" />
      <LayoutContainer className="pt-2">
        <LinearBreadcrumbs back />
        {productsLoading ? (
          <PageLoader />
        ) : (
          <Row>
            <h5 className="page-header">{firstProduct.vendor.name}</h5>
            <h6 className="mb-4 text-muted">{firstProduct.offeringDescription}</h6>
            {products.map((p) => (
              <Product key={p.id} offeringId={offeringId} {...p} />
            ))}
          </Row>
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
        <Link
          to={`/offerings/${offeringId}/products/${id}`}
          className="stretched-link"
        ></Link>
      </div>
    </Col>
  );
}
