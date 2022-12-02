import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodNav from "../components/FoodNav";
import FoodPrice from "../components/FoodPrice";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import makeTitle from "../modules/makeTitle";
import { anyMoney } from "../shared/react/Money";
import { useOffering } from "../state/useOffering";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Stack from "react-bootstrap/Stack";
import { Helmet } from "react-helmet-async";
import { useParams } from "react-router-dom";

export default function FoodDetails() {
  let { offeringId, productId } = useParams();
  productId = parseInt(productId, 10);

  const { vendors, products, cart, initializeToOffering, error, loading } = useOffering();

  React.useEffect(() => {
    initializeToOffering(offeringId);
  }, [initializeToOffering, offeringId]);

  if (loading) {
    return <PageLoader />;
  }

  const product = _.find(products, (p) => p.productId === productId);

  if (error || !product) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const vendor = _.find(vendors, (v) => v.id === product.vendorId);
  const title = makeTitle(product.name, vendor.name, t("food:title"));
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
        h={325}
        width={500}
      />
      <LayoutContainer top>
        <h3 className="mb-2">{product.name}</h3>
        <Stack direction="horizontal" gap={3} className="mb-2 align-items-center">
          <FoodPrice {...product} fs={4} />
          <div className="ms-auto">
            <FoodCartWidget product={product} size="lg" />
          </div>
        </Stack>
        <p>
          {product.isDiscounted
            ? t("food:from_vendor_with_discount", {
                vendorName: vendor.name,
                discountAmount: product.discountAmount,
              })
            : t("food:from_vendor", { vendorName: vendor.name })}
        </p>
        {anyMoney(product.noncashLedgerContributionAmount) && (
          <div className={clsx("mt-2")}>
            {t("food:noncash_ledger_contribution_available", {
              amount: product.noncashLedgerContributionAmount,
            })}
          </div>
        )}
        <hr />
        <h5 className="mt-2 mb-2">{t("food:details_header")}</h5>
        <p>{product.description}</p>
      </LayoutContainer>
    </>
  );
}
