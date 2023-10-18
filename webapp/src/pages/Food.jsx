import api from "../api";
import foodHeaderImage from "../assets/images/onboarding-food.jpg";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import WaitingListPage from "../components/WaitingListPage";
import { mdp, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Card from "react-bootstrap/Card";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

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
      {isEmpty(foodOfferings?.items) ? (
        <WaitingListPage
          feature="food"
          imgSrc={foodHeaderImage}
          imgAlt="Food Market"
          title={t("food:title")}
          text={mdp("food:intro")}
        />
      ) : (
        <>
          <img
            src={foodHeaderImage}
            alt={t("food:title")}
            className="thin-header-image"
          />
          <LayoutContainer top gutters>
            <h2>{t("food:title")}</h2>
            <p>{t("food:intro")}</p>
          </LayoutContainer>
        </>
      )}
      <hr className="my-4" />
      {offeringsLoading && <PageLoader relative />}
      <LayoutContainer gutters>
        {!isEmpty(foodOfferings?.items) && (
          <Row>
            <h4 className="mb-3">{t("food:current_offerings")}</h4>
            {foodOfferings?.items.map((o) => (
              <Offering key={o.id} {...o} />
            ))}
          </Row>
        )}
        {isEmpty(foodOfferings?.items) && !offeringsLoading && (
          <p>{t("food:no_offerings")}</p>
        )}
        <hr />
        <h4 className="mb-3">
          <Link to="/order-history" className="text-decoration-none">
            <span className="text-dark me-1">{t("food:previous_orders")}</span>
            <i className="bi-arrow-right"></i>
          </Link>
        </h4>
      </LayoutContainer>
    </>
  );
}

function Offering({ id, description, image, closesAt }) {
  return (
    <Col xs={12} className="mb-4">
      <Card>
        <Card.Body className="p-2">
          <Stack direction="horizontal" gap={3}>
            <SumaImage
              image={image}
              width={100}
              h={80}
              alt={description}
              className="border rounded"
            />
            <div>
              <Card.Link
                as={RLink}
                href={`/food/${id}`}
                state={{ fromIndex: true }}
                className="h6 mb-0"
              >
                {description}
              </Card.Link>
              <Card.Text className="text-secondary small">
                {t("food:available_until")} {dayjs(closesAt).format("ll")}
              </Card.Text>
            </div>
          </Stack>
        </Card.Body>
      </Card>
    </Col>
  );
}
