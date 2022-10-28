import api from "../api";
import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
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
      default: {},
      pickData: true,
    }
  );
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
            {foodOfferings.map((o) => (
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
                        href={`/offering/${o.vendorId}`}
                        as={RLink}
                      >
                        Shop
                      </Button>
                    </Stack>
                  </Card.Body>
                </Card>
              </Col>
            ))}
          </Row>
        </LayoutContainer>
      )}
    </>
  );
}
