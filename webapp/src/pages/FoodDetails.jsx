import BackBreadcrumb from "../components/BackBreadcrumb.jsx";
import CartIconButtonForNav from "../components/CartIconButtonForNav.jsx";
import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodPrice from "../components/FoodPrice";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading.jsx";
import PageLayout from "../components/PageLayout.jsx";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { dt, t } from "../localization";
import makeTitle from "../modules/makeTitle";
import { anyMoney, intToMoney } from "../shared/money";
import Money from "../shared/react/Money";
import useOffering from "../state/useOffering";
import clsx from "clsx";
import find from "lodash/find";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
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
    return (
      <PageLayout {...PAGE_LAYOUT_PROPS}>
        <PageLoader buffered />
      </PageLayout>
    );
  }

  if (error || !product) {
    const errorScreenProps = {};
    if (!error) {
      errorScreenProps.body = t("food.product_404");
      errorScreenProps.actionLabel = t("common.back");
      errorScreenProps.actionHref = `/food/${offeringId}`;
    }
    return (
      <PageLayout {...PAGE_LAYOUT_PROPS}>
        <LayoutContainer top>
          <ErrorScreen {...errorScreenProps} />
        </LayoutContainer>
      </PageLayout>
    );
  }

  const vendor = find(vendors, (v) => v.id === product.vendor.id);
  const title = makeTitle(product.name, vendor.name, t("food.title"));
  return (
    <PageLayout
      {...PAGE_LAYOUT_PROPS}
      stickyNavAddon={<CartIconButtonForNav offeringId={offeringId} cart={cart} />}
    >
      <Helmet>
        <title>{title}</title>
      </Helmet>
      <LayoutContainer gutters>
        <BackBreadcrumb back={`/food/${offeringId}`} />
        <PageHeading level={1} className="mb-3">
          {dt(product.name)}
        </PageHeading>
      </LayoutContainer>
      <SumaImage
        image={product.images[0]}
        className="w-100"
        params={{ crop: "center" }}
        h={325}
        width={500}
        variant="dark"
      />
      <LayoutContainer gutters top>
        <Row>
          <Col>
            <FoodPrice
              {...product}
              vendorName={vendor.name}
              fs={4}
              className="mb-2 lh-1 gap-2"
            />
          </Col>
          <Col>
            <div className="text-end">
              <FoodCartWidget
                product={product}
                onQuantityChange={(q) =>
                  setItemSubtotal(q * product.customerPrice.cents || 0)
                }
                size="lg"
              />
              <div
                className={clsx("me-4", !anyMoney(intToMoney(itemSubtotal)) && "d-none")}
              >
                <div className="mt-2 small text-secondary">{t("food.item_subtotal")}</div>
                <Money className="text-muted">{intToMoney(itemSubtotal)}</Money>
              </div>
            </div>
          </Col>
        </Row>
      </LayoutContainer>
      <hr className="my-4" />
      <LayoutContainer gutters>
        <Row>
          <h5>{t("food.from_vendor", { vendorName: vendor.name })}</h5>
          <h4>{t("food.details_header")}</h4>
          <div>{dt(product.description)}</div>
        </Row>
      </LayoutContainer>
    </PageLayout>
  );
}

const PAGE_LAYOUT_PROPS = { gutters: false, top: true };
