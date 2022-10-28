import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import ErrorScreen from "../components/ErrorScreen";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
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
  return (
    <>
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
                    <h5>{name}</h5>
                    <h6 className="mb-0">
                      <Money className={clsx("me-2", discountedPrice && "text-success")}>
                        {discountedPrice || price}
                      </Money>
                      {discountedPrice && (
                        <strike>
                          <Money>{price}</Money>
                        </strike>
                      )}
                    </h6>
                    <p>{weight}</p>
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
