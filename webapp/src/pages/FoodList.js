import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FoodCart from "../components/FoodCart";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
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
  const { state, loading, error } = useAsyncFetch(getFoodOfferingProducts, {
    default: {},
    pickData: true,
  });
  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const { items, offering } = state;
  const titleParts = [offering?.description, t("food:title"), t("titles:suma_app")];
  return (
    <>
      <Helmet>
        <title>{titleParts.join(" | ")}</title>
      </Helmet>
      <FoodCart startElement={<h5 className="m-0">{offering?.description}</h5>} />
      {offering && (
        <SumaImage image={offering.image} h={140} className="thin-header-image" />
      )}
      <LayoutContainer className="pt-2">
        {loading && <PageLoader />}
        {!loading && (
          <>
            {_.isEmpty(items) && mdp("food:no_products_md")}
            {!_.isEmpty(items) && (
              <Row>
                <LinearBreadcrumbs back />
                {items.map((p) => (
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
  return (
    <Col xs={6} className="mb-2">
      <div className="position-relative">
        <SumaImage image={image} alt={name} className="w-100" w={225} h={150} />
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
