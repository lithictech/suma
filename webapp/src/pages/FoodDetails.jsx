import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import FoodNav from "../components/FoodNav";
import FoodPrice from "../components/FoodPrice";
import LayoutContainer from "../components/LayoutContainer";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
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
    return <PageLoader buffered />;
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
      <LayoutContainer gutters>
        <Row>
          <h3 className="mb-3">{product.name}</h3>
        </Row>
      </LayoutContainer>
      <SumaImage
        image={product.images[0]}
        className="w-100"
        params={{ crop: "center" }}
        h={325}
        width={500}
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
                <div className="mt-2 small text-secondary">{t("food:item_subtotal")}</div>
                <Money className="text-muted">{intToMoney(itemSubtotal)}</Money>
              </div>
            </div>
          </Col>
        </Row>
      </LayoutContainer>
      <hr className="my-4" />
      <LayoutContainer gutters>
        <Row>
          <h5>{t("food:from_vendor", { vendorName: vendor.name })}</h5>
          <h4>{t("food:details_header")}</h4>
          <p>{product.description}</p>
        </Row>
      </LayoutContainer>
    </>
  );
}
