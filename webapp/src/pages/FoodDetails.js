import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodNav from "../components/FoodNav";
import FoodPrice from "../components/FoodPrice";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import makeTitle from "../modules/makeTitle";
import Money, { anyMoney, intToMoney } from "../shared/react/Money";
import { useOffering } from "../state/useOffering";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import find from "lodash/find";
import React from "react";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import { useParams } from "react-router-dom";

export default function FoodDetails() {
  let { offeringId, productId } = useParams();
  productId = parseInt(productId, 10);

  const [itemSubtotal, setItemSubtotal] = React.useState(0);
  const { vendors, products, cart, initializeToOffering, error, loading } = useOffering();

  React.useEffect(() => {
    initializeToOffering(offeringId);
  }, [initializeToOffering, offeringId]);

  const product = find(products, (p) => p.productId === productId);
  const item = find(cart.items, (item) => item.productId === productId);

  React.useEffect(() => {
    if (!item) {
      return;
    }
    setItemSubtotal(item.quantity * product.customerPrice.cents || 0);
  }, [product, item]);

  if (loading) {
    return <PageLoader />;
  }

  if (error || !product) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const vendor = find(vendors, (v) => v.id === product.vendorId);
  const title = makeTitle(product.name, vendor.name, t("food:title"));

  const showCreditsAndDiscounts = product.maxQuantity <= 1;
  return (
    <>
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <FoodNav
        offeringId={offeringId}
        cart={cart}
        startElement={<LinearBreadcrumbs back={`/food/${offeringId}`} noBottom />}
      />
      <SumaImage
        image={product.images[0]}
        alt={product.name}
        className="w-100"
        params={{ crop: "center" }}
        h={325}
        width={500}
      />
      <LayoutContainer top>
        <h3 className="mb-3">{product.name}</h3>
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <div>
            <FoodPrice
              {...product}
              fs={4}
              className="mb-2 lh-1"
              showCreditsAndDiscounts={showCreditsAndDiscounts}
            />
            <p>
              {product.isDiscounted && showCreditsAndDiscounts
                ? t("food:from_vendor_with_discount", {
                    vendorName: vendor.name,
                    discountAmount: product.discountAmount,
                  })
                : t("food:from_vendor", { vendorName: vendor.name })}
            </p>
            {anyMoney(product.noncashLedgerContributionAmount) &&
              showCreditsAndDiscounts && (
                <div className={clsx("mt-2")}>
                  {t("food:noncash_ledger_contribution_available", {
                    amount: product.noncashLedgerContributionAmount,
                  })}
                </div>
              )}
          </div>
          <div className="ms-auto">
            <FoodCartWidget
              product={product}
              onQuantityChange={(q) =>
                setItemSubtotal(q * product.customerPrice.cents || 0)
              }
              size="lg"
            />
            <div
              className={clsx(
                "me-4 text-end",
                !anyMoney(intToMoney(itemSubtotal)) && "d-none"
              )}
            >
              <div className="mt-2 small text-secondary">{t("food:item_subtotal")}</div>
              <Money className="text-muted">{intToMoney(itemSubtotal)}</Money>
            </div>
          </div>
        </Stack>
        <hr />
        <h5 className="mt-2 mb-2">{t("food:details_header")}</h5>
        <p>{product.description}</p>
      </LayoutContainer>
    </>
  );
}
