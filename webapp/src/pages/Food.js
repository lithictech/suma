import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";

export default function Food() {
  const { state: foodOfferings, loading: listLoading } = useAsyncFetch(
    api.getFoodOfferings,
    {
      pickData: true,
    }
  );
  if (!foodOfferings && !listLoading) {
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
            <h5 className="page-header mb-4">Vendor Offerings</h5>
            {foodOfferings.items.map((o) => (
              <Offering key={o.id} {...o} />
            ))}
          </Row>
        </LayoutContainer>
      )}
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
              href={`/offerings/${id}/products`}
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
