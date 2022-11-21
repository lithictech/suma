import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { md, mdp, t } from "../localization";
import Money from "../shared/react/Money";
import { useOffering } from "../state/useOffering";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link, useNavigate, useParams } from "react-router-dom";

export default function FoodCart() {
  const { id: offeringId } = useParams();
  const navigate = useNavigate();
  const { cart, products, vendors, error, loading, initializeToOffering } = useOffering();

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
  if (loading) {
    return <PageLoader />;
  }
  function handleCheckout(e) {
    e.preventDefault();
    api
      .startCheckout({ offeringId })
      .then(api.pickData)
      .then((d) => navigate(`/checkout/${d.id}`, { state: { checkout: d } }))
      .catch((e) => {
        // TODO: Add error toast
        console.error(e);
      });
  }
  const productsById = Object.fromEntries(products.map((p) => [p.productId, p]));
  const vendorsById = Object.fromEntries(vendors.map((v) => [v.id, v]));
  return (
    <>
      <LayoutContainer>
        {_.isEmpty(cart.items) && md("food:no_cart_items_md")}
        {!_.isEmpty(cart.items) && (
          <Row>
            <LinearBreadcrumbs back />
            <Stack direction="horizontal" gap={3} className="align-items-end">
              <h4>{t("food:cart_title")}</h4>
              <span className="text-secondary ms-auto">{t("food:price")}</span>
            </Stack>
            <hr />
            {cart.items.map((item) => {
              const product = productsById[item.productId];
              const vendor = vendorsById[product.vendorId];
              return (
                <CartItem
                  key={item.productId}
                  offeringId={offeringId}
                  product={product}
                  vendor={vendor}
                />
              );
            })}
            <Container className="d-flex align-items-end flex-column fs-6">
              {mdp("food:subtotal_items_md", {
                totalItems: cart.items.length,
                customerCost: cart.customerCost,
              })}
              <Button onClick={handleCheckout} variant="success">
                {t("food:continue_to_checkout")}
              </Button>
            </Container>
          </Row>
        )}
      </LayoutContainer>
    </>
  );
}

function CartItem({ offeringId, product, vendor }) {
  const { productId, name, isDiscounted, customerPrice, undiscountedPrice, images } =
    product;
  return (
    <>
      <Col xs={12} className="mb-3">
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <Link to={`/product/${offeringId}-${productId}`} className="flex-shrink-0">
            <SumaImage image={images[0]} alt={name} className="w-100" w={100} h={100} />
          </Link>
          <div>
            <Link to={`/product/${offeringId}-${productId}`}>
              <h6 className="mb-0">{name}</h6>
            </Link>
            <p className="mb-1 text-secondary">
              <small>{t("food:from_vendor", { vendorName: vendor.name })}</small>
            </p>
            <FoodCartWidget product={product} />
          </div>
          <p className="ms-auto fs-6">
            <Money className={clsx("me-2", isDiscounted && "text-success")}>
              {customerPrice}
            </Money>
            {isDiscounted && (
              <strike>
                <Money>{undiscountedPrice}</Money>
              </strike>
            )}
          </p>
        </Stack>
      </Col>
      <hr className="mb-3 mt-0" />
    </>
  );
}
