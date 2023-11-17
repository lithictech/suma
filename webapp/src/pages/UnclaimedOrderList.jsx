import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import ErrorScreen from "../components/ErrorScreen";
import FormButtons from "../components/FormButtons";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import OrderDetail from "../components/OrderDetail";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { md, mdp, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Badge from "react-bootstrap/Badge";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";
import Stack from "react-bootstrap/Stack";

export default function UnclaimedOrderList() {
  const [claimedOrder, setClaimedOrder] = React.useState({});
  const {
    state: unclaimedOrders,
    replaceState,
    loading,
    error,
  } = useAsyncFetch(api.getUnclaimedOrderHistory, {
    default: {},
    pickData: true,
  });

  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const handleOrderClaim = (o) => {
    setClaimedOrder(o);
    replaceState({ items: unclaimedOrders.items.filter((order) => order.id !== o.id) });
  };
  const { items } = unclaimedOrders;
  return (
    <>
      <LayoutContainer gutters top>
        <LinearBreadcrumbs back />
        <h2>{t("food:unclaimed_order_history_title")}</h2>
        <p>{t("food:unclaimed_order_history_intro")}</p>
      </LayoutContainer>
      <hr className="my-4" />
      <ClaimedOrderModal claimedOrder={claimedOrder} onHide={() => setClaimedOrder({})} />
      <LayoutContainer gutters>
        {!loading ? (
          <>
            {!isEmpty(items) && (
              <Stack gap={3}>
                {items.map((o) => (
                  <Card key={o.id} className="p-0">
                    <Card.Body className="px-2 pb-4">
                      <OrderDetail state={o} onOrderClaim={(o) => handleOrderClaim(o)} />
                    </Card.Body>
                  </Card>
                ))}
              </Stack>
            )}
          </>
        ) : (
          <PageLoader />
        )}
      </LayoutContainer>
      {isEmpty(items) && !loading && (
        <>
          <LayoutContainer gutters>{mdp("food:no_orders_to_claim")}</LayoutContainer>
          <hr className="my-4" />
          <LayoutContainer gutters>
            <div className="button-stack">
              <Button variant="primary" href="/order-history" as={RLink}>
                <i className="bi bi-bag-check-fill me-2"></i>
                {t("food:order_history_title")}
              </Button>
            </div>
          </LayoutContainer>
        </>
      )}
    </>
  );
}

function ClaimedOrderModal({ claimedOrder, onHide }) {
  return (
    <Modal show={!isEmpty(claimedOrder)} onHide={onHide} centered>
      <Modal.Header closeButton>
        <Modal.Title>{t("food:order_claimed")}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <div className="mt-4 d-flex justify-content-center align-items-center flex-column">
          <ScrollTopOnMount />
          <AnimatedCheckmark />
          <p className="mt-2 fs-4 w-75 text-center">
            {t("food:order_for_claimed_on", {
              serial: claimedOrder.serial,
              fulfilledAt: dayjs(claimedOrder.fulfilledAt).format("lll"),
            })}
          </p>
          <Stack gap={3}>
            {claimedOrder?.items?.map(({ image, name, customerPrice, quantity }) => (
              <Card key={name}>
                <Card.Body>
                  <Stack direction="horizontal" gap={3} className="align-items-start">
                    <SumaImage
                      image={image}
                      width={80}
                      h={80}
                      className="border rounded"
                    />
                    <div className="text-align-start">
                      <div className="lead">{name}</div>
                      <Badge bg="secondary" className="fs-6">
                        {md("food:price_times_quantity", {
                          price: customerPrice,
                          quantity,
                        })}
                      </Badge>
                    </div>
                  </Stack>
                </Card.Body>
              </Card>
            ))}
          </Stack>
          <div className="mt-2">
            <FormButtons
              primaryProps={{
                type: "button",
                variant: "outline-secondary",
                children: t("common:close"),
                onClick: () => onHide(),
              }}
              secondaryProps={{
                variant: "outline-primary",
                children: t("food:view_order"),
                href: `/order/${claimedOrder.id}`,
                as: RLink,
              }}
            />
          </div>
        </div>
      </Modal.Body>
    </Modal>
  );
}
