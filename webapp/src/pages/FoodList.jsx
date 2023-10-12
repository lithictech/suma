import ErrorScreen from "../components/ErrorScreen";
import FoodNav from "../components/FoodNav";
import FoodPrice from "../components/FoodPrice";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { t, mdp } from "../localization";
import makeTitle from "../modules/makeTitle";
import { useOffering } from "../state/useOffering";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import { Link, useNavigate, useParams, useLocation } from "react-router-dom";

export default function FoodList() {
  const { id: offeringId } = useParams();
  const navigate = useNavigate();
  const { state: locationState } = useLocation();

  const { offering, cart, products, initializeToOffering, error, loading } =
    useOffering();

  React.useEffect(() => {
    initializeToOffering(offeringId);
  }, [initializeToOffering, offeringId]);

  React.useEffect(() => {
    if (products.length !== 1 || !locationState?.fromIndex) {
      // We can auto-redirect when coming from the index, and when we have just one product
      return;
    }
    const firstProduct = products[0];
    if (firstProduct.offeringId !== Number(offeringId)) {
      // The offering hasn't finished initializing yet
      return;
    }
    navigate(`/product/${offeringId}/${firstProduct.productId}`, { replace: true });
  }, [locationState?.fromIndex, navigate, offeringId, products]);

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
      {offering.image && (
        <SumaImage
          image={offering.image}
          w={500}
          h={140}
          params={{ crop: "center" }}
          className="thin-header-image"
        />
      )}
      <FoodNav
        offeringId={offeringId}
        cart={cart}
        startElement={
          <Stack gap={2}>
            <LinearBreadcrumbs back="/food" noBottom />
            <h3 className="m-0">{offering.description}</h3>
          </Stack>
        }
      />
      <LayoutContainer className="pt-4">
        {loading && <PageLoader />}
        {!loading && (
          <>
            {isEmpty(products) && mdp("food:no_products")}
            {!isEmpty(products) && (
              <Row>
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
  const { productId, name, images, outOfStock } = product;
  return (
    <Col xs={6} className="mb-4">
      <div className="position-relative">
        <SumaImage image={images[0]} alt={name} className="w-100" w={225} h={150} />
        <h5 className="mb-2 mt-2">{name}</h5>
        {outOfStock ? (
          <p className="text-secondary">{t("food:currently_unavailable")}</p>
        ) : (
          <>
            <FoodPrice fs={5} {...product} />
          </>
        )}
        <Link to={`/product/${offeringId}/${productId}`} className="stretched-link" />
      </div>
    </Col>
  );
}