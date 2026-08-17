import CartIconButtonForNav from "../components/CartIconButtonForNav";
import ErrorScreen from "../components/ErrorScreen";
import FoodPrice from "../components/FoodPrice";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading";
import PageLayout from "../components/PageLayout";
import PageLoader from "../components/PageLoader";
import SoldOutText from "../components/SoldOutText";
import SumaImage from "../components/SumaImage";
import { dt, t } from "../localization";
import makeTitle from "../modules/makeTitle";
import useOffering from "../state/useOffering";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Button from "../ui/Button";
import Col from "../ui/Col";
import Row from "../ui/Row";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Helmet } from "react-helmet-async";
import { Link, useNavigate, useParams, useLocation } from "react-router-dom";

export default function FoodList() {
  const { id: offeringId } = useParams();
  const navigate = useNavigate();
  const { state: locationState } = useLocation();

  const { offering, cart, listableProducts, initializeToOffering, error, loading } =
    useOffering();

  React.useEffect(() => {
    initializeToOffering(offeringId);
  }, [initializeToOffering, offeringId]);

  React.useEffect(() => {
    if (listableProducts.length !== 1 || !locationState?.fromIndex) {
      // We can auto-redirect when coming from the index, and when we have just one product
      return;
    }
    const firstProduct = listableProducts[0];
    if (firstProduct.offeringId !== Number(offeringId)) {
      // The offering hasn't finished initializing yet
      return;
    }
    navigate(`/product/${offeringId}/${firstProduct.productId}`, { replace: true });
  }, [locationState?.fromIndex, navigate, offeringId, listableProducts]);

  if (error) {
    return (
      <PageLayout {...PAGE_LAYOUT_PROPS}>
        <LayoutContainer top>
          <ErrorScreen />
        </LayoutContainer>
      </PageLayout>
    );
  }
  if (loading) {
    return (
      <PageLayout {...PAGE_LAYOUT_PROPS}>
        <PageLoader buffered />
      </PageLayout>
    );
  }
  const title = makeTitle(offering.description, t("food.title"));
  return (
    <PageLayout
      {...PAGE_LAYOUT_PROPS}
      stickyNavAddon={
        <CartIconButtonForNav offeringId={offeringId as string} cart={cart} />
      }
    >
      <Helmet>
        <title>{title}</title>
      </Helmet>
      {offering.image && (
        <SumaImage
          image={offering.image}
          w={500}
          h={140}
          placeholderHeight={140}
          params={{ crop: "center" }}
          className="thin-header-image"
        />
      )}
      <LayoutContainer gutters>
        <div className="hstack my-3">
          <BreadcrumbBack back="/food">
            <PageHeading className="mb-0">{dt(offering.description)}</PageHeading>
          </BreadcrumbBack>
        </div>
        {isEmpty(listableProducts) ? (
          <>
            {t("food.no_products")}
            <div className="button-stack w-100">
              <Button href="/food" title={t("food.title")}>
                {t("food.available_offerings")}
              </Button>
            </div>
          </>
        ) : (
          <Row>
            {listableProducts.map((p) => (
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
    </PageLayout>
  );
}

interface ProductProps {
  product: PricedOfferingProduct;
  offeringId?: string;
  cart: Cart;
}

function Product({ product, offeringId, cart }: ProductProps) {
  const { productId, name, images, outOfStock } = product;
  return (
    <Col
      xs={6}
      className="mb-4 border-bottom border-secondary border-opacity-50 position-relative"
    >
      <SumaImage image={images[0]} className="w-100" width={225} h={150} variant="dark" />
      <h5 className="mb-2 mt-2">{dt(name)}</h5>
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

const PAGE_LAYOUT_PROPS = { gutters: false, top: false, appNav: true };
