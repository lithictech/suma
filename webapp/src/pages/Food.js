import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import CartIcon from "../components/CartIcon";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import _ from "lodash";
import React from "react";
import { Stack } from "react-bootstrap";
import Card from "react-bootstrap/Card";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";

export default function Food() {
  const {
    state: foodOfferings,
    loading: offeringsLoading,
    error: offeringsError,
  } = useAsyncFetch(api.getCommerceOfferings, {
    pickData: true,
  });
  if (offeringsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  return (
    <>
      <img src={foodImage} alt={t("food:title")} className="thin-header-image" />
      <LayoutContainer top gutters>
        <h2>{t("food:title")}</h2>
        <p className="text-secondary">{t("food:intro")}</p>
      </LayoutContainer>
      <hr className="my-4" />
      {offeringsLoading && <PageLoader relative />}
      <LayoutContainer gutters>
        {!_.isEmpty(foodOfferings?.items) && (
          <Row>
            <h4 className="mb-3">{t("food:current_offerings")}</h4>
            {foodOfferings?.items.map((o) => (
              <Offering key={o.id} {...o} />
            ))}
          </Row>
        )}
        {_.isEmpty(foodOfferings?.items) && !offeringsLoading && (
          <p>{t("food:no_offerings")}</p>
        )}
      </LayoutContainer>
    </>
  );
}

function Offering({ id, description, image, closesAt, cartItems }) {
  cartItems = cartItems || [];
  return (
    <Col xs={12} className="mb-4">
      <Card>
        <Card.Body>
          <Stack direction="horizontal" gap={3}>
            <SumaImage
              image={image}
              width={60}
              h={60}
              alt={description}
              className="border rounded"
            />
            <div>
              <Card.Link as={RLink} href={`/food/${id}`} className="h6 mb-0">
                {description}
              </Card.Link>
              <Card.Text className="text-secondary small">
                {t("food:available_until")} {dayjs(closesAt).format("ll")}
                {cartItems.length === 0 && (
                  <>
                    {" · "}
                    <RLink to={`/food/${id}`} className="text-decoration-none">
                      <CartIcon className="text-success" cart={{}} />
                    </RLink>
                  </>
                )}
              </Card.Text>
            </div>
          </Stack>
        </Card.Body>
      </Card>
    </Col>
  );
}
