// import foodImage from "../assets/images/onboarding-food.jpg";
// import WaitingListPage from "../components/WaitingListPage";
// import { mdp, t } from "../localization";
import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import FoodWidget from "../components/FoodWidget";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Link, useSearchParams } from "react-router-dom";

export default function Food() {
  const [params] = useSearchParams();
  const getFoodOfferings = React.useCallback(() => {
    // TODO: Get all offerings information or make separate
    // API call to get specific vendor offering list.
    // Also, refactor the product loop in the return block below accordingly.
    return api.getFoodOfferings({ id: params.get("id") || null });
  }, [params]);
  const { state: foodOfferings, loading: listLoading } = useAsyncFetch(getFoodOfferings, {
    default: {},
    pickData: true,
  });
  return (
    <>
      <AppNav />
      <img src={foodImage} alt="food" className="thin-header-image" />
      {listLoading ? (
        <PageLoader />
      ) : (
        <FoodContent offerings={foodOfferings} params={params} />
      )}
    </>
  );
}

function FoodContent({ offerings, params }) {
  // TODO: Recieve this cart from backend API once cart mechanism is done
  const cart = [{ key: 1, productId: 3, maxQuantity: 200, quantity: 2 }];
  return (
    <LayoutContainer gutters top>
      {!params.get("id") ? (
        <Row>
          <h5 className="page-header mb-4">Vendor Offerings</h5>
          {offerings.map((o) => (
            <Col xs={12} key={o.vendorId} className="mb-4">
              <Card>
                <Card.Body>
                  <Stack direction="horizontal" gap={2}>
                    <div>
                      <Card.Title className="h5">{o.vendorName}</Card.Title>
                      <Card.Subtitle className="mb-2 text-muted text-capitalize">
                        {o.offeringType.map((type, idx) => (
                          <span key={type}>
                            {type}
                            {o.offeringType.length > 1 &&
                              o.offeringType.length !== idx + 1 &&
                              " · "}
                          </span>
                        ))}
                      </Card.Subtitle>
                      <Card.Text className="text-secondary">
                        Closing on {dayjs(o.openingDate).format("ll")}
                      </Card.Text>
                    </div>
                    <Button
                      variant="success"
                      className="ms-auto"
                      href={`/food?id=${o.vendorId}`}
                    >
                      Shop
                    </Button>
                  </Stack>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>
      ) : (
        <Row>
          <LinearBreadcrumbs back />
          <h3 className="mb-4">{offerings[Number(params.get("id"))].vendorName}</h3>
          {offerings[Number(params.get("id"))].offeringProducts.map((f) => (
            <Col xs={6} key={f.id} className="mb-4">
              <div className="position-relative">
                <Link to={`/food-details?id=${f.id}`}>
                  {/* TODO: refactor image src with correct link */}
                  <img src="/temporary-food-chicken.jpg" alt={f.name} className="w-100" />
                </Link>
                <div className="food-widget-container position-absolute">
                  {cart.map((product) =>
                    product.productId === f.id ? (
                      <FoodWidget key={f.id} {...product} />
                    ) : (
                      <FoodWidget key={f.id} {...f} />
                    )
                  )}
                </div>
              </div>
              <h5>{f.name}</h5>
              <h6 className="mb-0">
                <Money className={clsx("me-2", f.discountedPrice && "text-success")}>
                  {f.discountedPrice || f.price}
                </Money>
                {f.discountedPrice && (
                  <strike>
                    <Money>{f.price}</Money>
                  </strike>
                )}
              </h6>
              <p>{f.weight}</p>
            </Col>
          ))}
        </Row>
      )}
    </LayoutContainer>
  );
}
