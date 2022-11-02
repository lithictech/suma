import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import _ from "lodash";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
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
      <img src={foodImage} alt="food" className="thin-header-image" />
      <LayoutContainer top gutters>
        <h2>{t("food:title")}</h2>
        <p className="text-secondary">{t("food:intro")}</p>
      </LayoutContainer>
      <hr className="my-4" />
      {offeringsLoading && <PageLoader />}
      <LayoutContainer gutters>
        {!_.isEmpty(foodOfferings?.items) && (
          <Row>
            <h4 className="mb-3">Vendor Offerings</h4>
            {foodOfferings?.items.map((o) => (
              <Offering key={o.id} {...o} />
            ))}
          </Row>
        )}
        {_.isEmpty(foodOfferings?.items) && !offeringsLoading && (
          <p>There are no food offerings currently available, please check back later.</p>
        )}
      </LayoutContainer>
    </>
  );
}

function Offering({ id, description, closesAt }) {
  return (
    <Col xs={12} key={id} className="mb-4">
      <Card>
        <Card.Body>
          <Stack direction="horizontal" gap={2}>
            {/*TODO: display image after backend images is setup*/}
            <div>
              <Card.Title className="h5">{description}</Card.Title>
              <Card.Text className="text-secondary">
                Closing in {dayjs(closesAt).format("ll")}
              </Card.Text>
            </div>
            <Button
              variant="success"
              className="ms-auto"
              href={`/offering/${id}`}
              as={RLink}
            >
              Shop
            </Button>
          </Stack>
        </Card.Body>
      </Card>
    </Col>
  );
}
