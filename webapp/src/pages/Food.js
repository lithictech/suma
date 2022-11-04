import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import ErrorScreen from "../components/ErrorScreen";
import FoodCart from "../components/FoodCart";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
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
  } = useAsyncFetch(api.getFoodOfferings, {
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
      <AppNav />
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

function Offering({ id, description, closesAt, cartItems }) {
  cartItems = cartItems || [];
  // TODO: Remove
  const tempImgSrc =
    "https://www.instacart.com/image-server/72x/www.instacart.com/assets/domains/warehouse/logo/246/62c95c4e-90b1-4e94-b3e3-49ec806ee5ad.png";
  return (
    <Col xs={12} className="mb-4">
      <Card>
        <Card.Body>
          <Stack direction="horizontal" gap={3}>
            {/*TODO: display image after backend images is setup*/}
            <img
              src={tempImgSrc}
              alt={description}
              width="60px"
              className="border rounded"
            />
            <div>
              <Card.Link as={RLink} href={`/offering/${id}`} className="h6 mb-0">
                {description}
              </Card.Link>
              <Card.Text className="text-secondary small">
                {t("food:available_until")} {dayjs(closesAt).format("ll")}
                {cartItems.length > 0 && (
                  <>
                    {" · "}
                    <RLink to={`/offering/${id}`}>
                      <FoodCart inline className="text-success" />
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
