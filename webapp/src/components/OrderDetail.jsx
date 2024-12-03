import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import FormSaveCancel from "../components/FormSaveCancel";
import LayoutContainer from "../components/LayoutContainer";
import SumaImage from "../components/SumaImage";
import { dt, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import Money from "../shared/react/Money";
import useToggle from "../shared/react/useToggle";
import useErrorToast from "../state/useErrorToast";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import PressAndHold from "./PressAndHold";
import clsx from "clsx";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Form from "react-bootstrap/Form";
import Stack from "react-bootstrap/Stack";

export default function OrderDetail({ order, setOrder, gutters }) {
  return (
    <>
      <LayoutContainer gutters={gutters}>
        <Stack gap={3}>
          <div>
            <h3 className="mb-1">{t("food:order_serial", { serial: order.serial })}</h3>
            {dayjs(order.createdAt).format("lll")}
          </div>
          <PressAndHoldToClaim
            id={order.id}
            canClaim={order.canClaim}
            offeringDescription={order.offeringDescription}
            onOrderClaim={(o) => setOrder(o)}
          />
          <p className="mb-0">
            {t("food:labels:price", { price: order.customerCost })}
            {order.customerCost.cents !== order.undiscountedCost.cents && (
              <Money as="del" className="text-secondary ms-2">
                {order.undiscountedCost}
              </Money>
            )}
            <br />
            {t("food:labels:fees_and_taxes", { fees: order.handling, taxes: order.tax })}
            <br />
            {t("food:labels:total", { total: order.total })}
            {order.fundingTransactions.map(({ label, amount }) => (
              <React.Fragment key={label}>
                <br />
                {label}: <Money>{amount}</Money>
              </React.Fragment>
            ))}
            <br />
          </p>
          <FulfillmentOption order={order} onOrderUpdated={setOrder} />
          {!order.canClaim && order.fulfilledAt && (
            <Alert variant="info" className="mb-0">
              <ScrollTopOnMount />
              <Stack direction="horizontal" gap={3}>
                {t("food:order_for_claimed_on", {
                  offeringDescription: order.offeringDescription,
                  fulfilledAt: dayjs(order.fulfilledAt).format("lll"),
                })}
                <div className="ms-auto">
                  <AnimatedCheckmark />
                </div>
              </Stack>
            </Alert>
          )}
          <SumaImage
            image={order.image}
            w={350}
            height={150}
            className="rounded responsive-wide-image"
          />
          <hr className="my-0" />
          <Card.Text className="h4 mb-0">
            {t("food:labels:items_count", { itemCount: order.items.length })}
          </Card.Text>
          {order.items.map(({ name, description, customerPrice, quantity }, i) => (
            <Stack key={i} className="justify-content-between align-items-start" gap={1}>
              <div className="lead">{name}</div>
              <div>
                {t("food:price_times_quantity", {
                  price: customerPrice,
                  quantity,
                })}
              </div>
              <div className="text-secondary">{dt(description)}</div>
            </Stack>
          ))}
        </Stack>
      </LayoutContainer>
    </>
  );
}

function FulfillmentOption({ order, onOrderUpdated }) {
  const editing = useToggle(false);
  const screenLoader = useScreenLoader();
  const [optionId, setOptionId] = React.useState(order.fulfillmentOption?.id || 0);
  const { showErrorToast } = useErrorToast();

  if (isEmpty(order.fulfillmentOptionsForEditing)) {
    if (!order.fulfillmentOption) {
      // No options, and nothing is selected, so nothing to show
      return null;
    }
    // No options, but something is selected, so show it
    return (
      <div>
        <h6 className="fw-bold">{order.fulfillmentConfirmation}</h6>
        <span>{order.fulfillmentOption.description}</span>
      </div>
    );
  }

  if (editing.isOff) {
    return (
      <span>
        <h6 className="fw-bold lh-lg">
          {order.fulfillmentConfirmation}
          {order.fulfillmentOptionEditable && (
            <Button
              variant="link"
              className="p-0 ms-2"
              onClick={() => {
                setOptionId(order.fulfillmentOption?.id || 0);
                editing.turnOn();
              }}
            >
              <i className="bi bi-pencil-fill" />
            </Button>
          )}
        </h6>
        {order.fulfillmentOption?.description || (
          <span className="text-secondary">{t("food:no_option_chosen")}</span>
        )}
      </span>
    );
  }
  function updateFulfillment(e) {
    e.preventDefault();
    screenLoader.turnOn();
    api
      .updateOrderFulfillment({ orderId: order.id, optionId: optionId })
      .then((r) => {
        editing.turnOff();
        screenLoader.turnOff();
        onOrderUpdated(r.data);
      })
      .catch((e) => {
        screenLoader.turnOff();
        showErrorToast(e, { extract: true });
      });
  }
  const chosenFulfillmentValid = order.fulfillmentOptionsForEditing.some(
    ({ id }) => id === optionId
  );

  return (
    <Form noValidate>
      <Form.Group>
        <h6 className="fw-bold lh-lg">{order.fulfillmentConfirmation}</h6>
        {order.fulfillmentOptionsForEditing.map((fo) => (
          <Form.Check
            key={fo.id}
            id={fo.id}
            name={fo.description}
            type="radio"
            label={fo.description}
            checked={optionId === fo.id}
            onChange={() => setOptionId(fo.id)}
          />
        ))}
      </Form.Group>
      <FormSaveCancel
        saveDisabled={!chosenFulfillmentValid}
        className="mt-2"
        onCancel={editing.turnOff}
        onSave={updateFulfillment}
      />
    </Form>
  );
}

function PressAndHoldToClaim({ id, canClaim, offeringDescription, onOrderClaim }) {
  const screenLoader = useScreenLoader();
  const { showErrorToast } = useErrorToast();
  const { handleUpdateCurrentMember } = useUser();

  if (!canClaim) {
    return null;
  }

  const handleOrderClaim = () => {
    screenLoader.turnOn();
    api
      .claimOrder({ orderId: id })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        screenLoader.turnOff();
        onOrderClaim(r.data);
      })
      .catch((e) => {
        screenLoader.turnOff();
        showErrorToast(e, { extract: true });
      });
  };
  return (
    <div className="text-center">
      <Alert variant="info mb-0">
        <p className="small mb-0">
          {t("food:claiming_instructions", { offeringDescription: offeringDescription })}
        </p>
        <PressAndHold size={200} onHeld={handleOrderClaim}>
          {t(
            "food:press_and_hold",
            {},
            {
              markdown: {
                overrides: {
                  p: {
                    props: {
                      className: "mb-0 fs-6",
                    },
                  },
                },
              },
            }
          )}
        </PressAndHold>
      </Alert>
    </div>
  );
}
