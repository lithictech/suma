import ErrorScreen from "../components/ErrorScreen";
import FoodNav from "../components/FoodNav";
import FoodPrice from "../components/FoodPrice";
import LayoutContainer from "../components/LayoutContainer";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SoldOutText from "../components/SoldOutText";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import makeTitle from "../modules/makeTitle";
import useOffering from "../state/useOffering";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
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
  if (loading) {
    return <PageLoader buffered />;
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
        startElement={<LinearBreadcrumbs back="/food" noBottom />}
      />
      <LayoutContainer gutters>
        <h2 className="mb-3">{offering.description}</h2>
        {isEmpty(products) ? (
          <>
            {t("food:no_products")}
            <div className="button-stack w-100">
              <Button href="/food" as={RLink} title={t("food:title")}>
                {t("food:available_offerings")}
              </Button>
            </div>
          </>
        ) : (
          <Row>
            {products.map((p) => (
              <Product
                key={p.productId}
                cart={cart}
                offeringId={offeringId}
                product={p}
              />
            ))}
          </Row>
        )}
      </LayoutContainer>
    </>
  );
}

function Product({ product, offeringId, cart }) {
  const { productId, name, images, outOfStock } = product;
  return (
    <Col
      xs={6}
      className="mb-4 border-bottom border-secondary border-opacity-50 position-relative"
    >
      <SumaImage image={images[0]} className="w-100" width={225} h={150} variant="dark" />
      <h5 className="mb-2 mt-2">{name}</h5>
      <p className="my-2">{product.vendor.name}</p>
      {outOfStock ? (
        <p className="mb-3 text-secondary">
          <SoldOutText cart={cart} product={product} />
        </p>
      ) : (
        <>
          <FoodPrice
            fs={5}
            className="mb-3 gap-2"
            isDiscounted={product.isDiscounted}
            undiscountedPrice={product.undiscountedPrice}
            displayableCashPrice={product.displayableCashPrice}
          />
        </>
      )}
      <Link to={`/product/${offeringId}/${productId}`} className="stretched-link" />
    </Col>
  );
}
