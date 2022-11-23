import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodNav from "../components/FoodNav";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { t, mdp } from "../localization";
import makeTitle from "../modules/makeTitle";
import Money from "../shared/react/Money";
import { useOffering } from "../state/useOffering";
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

  const { offering, cart, products, initializeToOffering, error, loading } =
    useOffering();

  React.useEffect(() => {
    initializeToOffering(offeringId);
  }, [initializeToOffering, offeringId]);

  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }

  const title = makeTitle(offering.description, t("food:title"));
  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <FoodNav
        offeringId={offeringId}
        cart={cart}
        startElement={<h5 className="m-0">{offering.description}</h5>}
      />
      {offering.image && (
        <SumaImage image={offering.image} w={500} h={140} className="thin-header-image" />
      )}
      <LayoutContainer className="pt-2">
        {loading && <PageLoader />}
        {!loading && (
          <>
            {_.isEmpty(products) && mdp("food:no_products_md")}
            {!_.isEmpty(products) && (
              <Row>
                <LinearBreadcrumbs back="/food" />
                {products.map((p) => (
                  <Product key={p.productId} offeringId={offeringId} product={p} />
                ))}
              </Row>
            )}
          </>
        )}
      </LayoutContainer>
    </>
  );
}

function Product({ product, offeringId }) {
  const { productId, name, isDiscounted, undiscountedPrice, customerPrice, images } =
    product;
  return (
    <Col xs={6} className="mb-2">
      <div className="position-relative">
        <SumaImage image={images[0]} alt={name} className="w-100" w={225} h={150} />
        <div className="food-widget-container position-absolute">
          <FoodCartWidget product={product} />
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
