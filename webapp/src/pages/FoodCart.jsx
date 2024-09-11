import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodPrice from "../components/FoodPrice";
import LayoutContainer from "../components/LayoutContainer";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { anyMoney } from "../shared/money";
import useErrorToast from "../state/useErrorToast";
import useOffering from "../state/useOffering";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
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
    return <PageLoader buffered />;
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
  const { items } = cart;
  return (
    <>
      <LayoutContainer gutters>
        <LinearBreadcrumbs back={`/food/${offeringId}`} />
        <Stack direction="horizontal" gap={3} className="align-items-end">
          <h4 className="mb-0">{t("food:cart_title")}</h4>
          <span className="text-secondary ms-auto">{t("food:price")}</span>
        </Stack>
      </LayoutContainer>
      <hr className="mt-2 mb-4" />
      <LayoutContainer gutters>
        {!isEmpty(items) ? (
          <Stack gap={4}>
            {items.map((item) => {
              const product = productsById[item.productId];
              const vendor = vendorsById[product.vendorId];
              return (
                <CartItem
                  key={product.name}
                  offeringId={offeringId}
                  product={product}
                  vendor={vendor}
                />
              );
            })}
          </Stack>
        ) : (
          <span>{t("food:no_cart_items")}</span>
        )}
      </LayoutContainer>
      <hr className="my-4" />
      <LayoutContainer gutters>
        {!isEmpty(items) ? (
          <Stack gap={2} className="align-items-end">
            <div>
              {t("food:subtotal_items", {
                totalItems: items.length,
                customerCost: cart.customerCost,
              })}
            </div>
            {anyMoney(cart.noncashLedgerContributionAmount) && (
              <div className="text-success">
                {t("food:cart_available_credit", {
                  amount: cart.noncashLedgerContributionAmount,
                })}
              </div>
            )}
            {anyMoney(cart.cashCost) && (
              <div>
                {t("food:cart_cash_cost", {
                  amount: cart.cashCost,
                })}
              </div>
            )}
            <Button onClick={handleCheckout} variant="success">
              {t("food:continue_to_checkout")}
            </Button>
          </Stack>
        ) : (
          <div className="button-stack">
            <Button href="/food" as={RLink} title={t("food:title")}>
              {t("food:available_offerings")}
            </Button>
          </div>
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
    displayableCashPrice,
    undiscountedPrice,
    images,
  } = product;
  return (
    <Stack direction="horizontal" gap={3} className="align-items-start">
      <Link to={`/product/${offeringId}/${productId}`}>
        <SumaImage image={images[0]} alt={name} className="w-100" w={100} h={100} />
      </Link>
      <div>
        <Link to={`/product/${offeringId}/${productId}`}>
          <h6 className="mb-2">{name}</h6>
        </Link>
        <p className="text-secondary mb-2 small">
          {t("food:from_vendor", { vendorName: vendor.name })}
        </p>
        <FoodCartWidget product={product} />
      </div>
      <div className="ms-auto text-end">
        <FoodPrice
          isDiscounted={isDiscounted}
          undiscountedPrice={undiscountedPrice}
          // We don't want to show noncash contributions here,
          // so use the customer price as the cash price.
          // except for turkey hacking holiday 2023.
          displayableCashPrice={displayableCashPrice}
          fs={6}
          bold={false}
          direction="vertical"
        />
      </div>
    </Stack>
  );
}
