import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import ErrorScreen from "../components/ErrorScreen";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Helmet } from "react-helmet-async";
import { Link, useParams } from "react-router-dom";

export default function FoodList() {
  const { offeringId } = useParams();
  const getFoodOfferingList = React.useCallback(() => {
    // TODO: Get all offerings information or make separate
    // API call to get specific vendor offering list.
    // Also, refactor the product loop in the return block below accordingly.
    return api.getFoodOfferingList({ offeringId: offeringId || null });
  }, [offeringId]);
  const {
    state: foodOfferingList,
    loading: listLoading,
    error: listError,
  } = useAsyncFetch(getFoodOfferingList, {
    default: {},
    pickData: true,
  });
  if (!foodOfferingList || listError) {
    return <ErrorScreen />;
  }
  // TODO: We assume that all names are capitalized
  const firstOfferingType =
    foodOfferingList?.offeringType && foodOfferingList.offeringType[0];
  const title = `${foodOfferingList.vendorName} | ${
    firstOfferingType ? firstOfferingType + " | " : t("food:title") + " | "
  }${t("titles:suma_app")}`;
  return (
    <>
      {!listLoading && (
        <Helmet>
          <title>{title}</title>
        </Helmet>
      )}
      <AppNav />
      <img src={foodImage} alt="food" className="thin-header-image" />
      {listLoading ? (
        <PageLoader />
      ) : (
        <LayoutContainer top>
          <Row>
            <LinearBreadcrumbs back />
            <h3 className="mb-4">{foodOfferingList.vendorName}</h3>
            {foodOfferingList.products.map(
              ({ id, name, price, discountedPrice, weight, maxQuantity, quantity }) => (
                <Col xs={6} key={id} className="mb-2">
                  <div className="position-relative">
                    {/* TODO: refactor image src with correct link */}
                    <img src="/temporary-food-chicken.jpg" alt={name} className="w-100" />
                    <div className="food-widget-container position-absolute">
                      <FoodWidget
                        productId={id}
                        maxQuantity={maxQuantity}
                        quantity={quantity}
                      />
                    </div>
                    <h6 className="mb-0 mt-2">{name}</h6>
                    <p className="mb-0 fs-5 fw-semibold">
                      <Money className={clsx("me-2", discountedPrice && "text-success")}>
                        {discountedPrice || price}
                      </Money>
                      {discountedPrice && (
                        <strike>
                          <Money>{price}</Money>
                        </strike>
                      )}
                    </p>
                    <p className="text-muted lh-1">{weight}</p>
                    <Link
                      to={`/offering-product/${id}`}
                      className="stretched-link"
                    ></Link>
                  </div>
                </Col>
              )
            )}
          </Row>
        </LayoutContainer>
      )}
    </>
  );
}
