import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodPrice from "../components/FoodPrice";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { md, t } from "../localization";
import { anyMoney } from "../shared/react/Money";
import { useErrorToast } from "../state/useErrorToast";
import { useOffering } from "../state/useOffering";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link, useNavigate, useParams } from "react-router-dom";

export default function FoodCart() {
  const { id: offeringId } = useParams();
  const navigate = useNavigate();
  const { cart, products, vendors, error, loading, initializeToOffering } = useOffering();
  const { showErrorToast } = useErrorToast();

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
      .catch((e) => showErrorToast(e, { extract: true }));
  }
  const productsById = Object.fromEntries(products.map((p) => [p.productId, p]));
  const vendorsById = Object.fromEntries(vendors.map((v) => [v.id, v]));
  return (
    <>
      <LayoutContainer>
        {isEmpty(cart.items) && md("food:no_cart_items")}
        {!isEmpty(cart.items) && (
          <Row>
            <LinearBreadcrumbs back={`/food/${offeringId}`} />
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
            <Stack gap={2} className="align-items-end">
              <div>
                {md("food:subtotal_items", {
                  totalItems: cart.items.length,
                  customerCost: cart.customerCost,
                })}
              </div>
              {anyMoney(cart.noncashLedgerContributionAmount) && (
                <div>
                  {md("food:cart_available_credit", {
                    amount: cart.noncashLedgerContributionAmount,
                  })}
                </div>
              )}
              <Button onClick={handleCheckout} variant="success">
                {t("food:continue_to_checkout")}
              </Button>
            </Stack>
          </Row>
        )}
      </LayoutContainer>
    </>
  );
}

function CartItem({ offeringId, product, vendor }) {
  const {
    productId,
    name,
    isDiscounted,
    customerPrice,
    undiscountedPrice,
    discountAmount,
    images,
  } = product;
  return (
    <>
      <Col xs={12} className="mb-3">
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <Link to={`/product/${offeringId}/${productId}`} className="flex-shrink-0">
            <SumaImage image={images[0]} alt={name} className="w-100" w={100} h={100} />
          </Link>
          <div>
            <Link to={`/product/${offeringId}/${productId}`}>
              <h6 className="mb-2">{name}</h6>
            </Link>
            <p className="text-secondary mb-2 small">
              {product.isDiscounted
                ? t("food:from_vendor_with_discount", {
                    vendorName: vendor.name,
                    discountAmount: discountAmount,
                  })
                : t("food:from_vendor", { vendorName: vendor.name })}
            </p>
            <FoodCartWidget product={product} />
          </div>
          <FoodPrice
            customerPrice={customerPrice}
            isDiscounted={isDiscounted}
            undiscountedPrice={undiscountedPrice}
            fs={6}
            bold={false}
          />
        </Stack>
      </Col>
      <hr className="mb-3 mt-0" />
    </>
  );
}
