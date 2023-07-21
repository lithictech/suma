import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import FormSaveCancel from "../components/FormSaveCancel";
import SumaImage from "../components/SumaImage";
import { md, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useLongPress from "../shared/react/useLongPress";
import useToggle from "../shared/react/useToggle";
import { useErrorToast } from "../state/useErrorToast";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Form from "react-bootstrap/Form";
import Spinner from "react-bootstrap/Spinner";
import Stack from "react-bootstrap/Stack";

export default function OrderDetail({ state, onOrderClaim, gutters }) {
  const [order, setOrder] = React.useState(state);
  return (
    <>
      <LayoutContainer gutters={gutters}>
        <Stack gap={3}>
          <div>
            <h3 className="mb-1">{t("food:order_serial", { serial: order.serial })}</h3>
            {dayjs(order.createdAt).format("lll")}
          </div>
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
          <div>
            <h6 className="fw-bold">{order.fulfillmentConfirmation}</h6>
            <FulfillmentOption order={order} onOrderUpdated={(o) => setOrder(o)} />
          </div>
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
                {md("food:price_times_quantity", {
                  price: customerPrice,
                  quantity,
                })}
              </div>
              <div className="text-secondary">{description}</div>
            </Stack>
          ))}
        </Stack>
        <PressAndHoldToClaim
          id={order.id}
          canClaim={order.canClaim}
          serial={order.serial}
          fulfilledAt={order.fulfilledAt}
          onOrderClaim={(o) => onOrderClaim(o)}
        />
      </LayoutContainer>
    </>
  );
}

function FulfillmentOption({ order, onOrderUpdated }) {
  const editing = useToggle(false);
  const screenLoader = useScreenLoader();
  const [optionId, setOptionId] = React.useState(0);
  const { showErrorToast } = useErrorToast();

  if (isEmpty(order.fulfillmentOptionsForEditing)) {
    return <span>{order.fulfillmentOption.description}</span>;
  }

  if (editing.isOff) {
    return (
      <span>
        {order.fulfillmentOption.description}
        {order.fulfillmentOptionsForEditing.length > 1 && (
          <Button
            variant="link"
            className="p-0 ms-2"
            onClick={() => {
              setOptionId(order.fulfillmentOption.id);
              editing.turnOn();
            }}
          >
            <i className="bi bi-pencil-fill"></i>
          </Button>
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

function PressAndHoldToClaim({ id, canClaim, serial, fulfilledAt, onOrderClaim }) {
  const screenLoader = useScreenLoader();
  const { showErrorToast } = useErrorToast();
  const { handleUpdateCurrentMember } = useUser();
  const buttonRef = React.useRef(null);

  const isPressed = useLongPress(() => {
    handleOrderClaim();
  }, 3000);

  if (!canClaim && !fulfilledAt) {
    return null;
  }
  if (!canClaim) {
    return (
      <div className="mt-4 text-center d-flex justify-content-center align-items-center flex-column">
        <AnimatedCheckmark scale={2} />
        <p className="mt-2 fs-4 w-75">
          {t("food:order_for_claimed_on", {
            serial: serial,
            fulfilledAt: dayjs(fulfilledAt).format("lll"),
          })}
        </p>
      </div>
    );
  }

  const handleOrderClaim = () => {
    buttonRef.current.disabled = true;
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
        buttonRef.current.disabled = false;
      });
  };
  return (
    <div className="text-center">
      <Alert variant="info mt-3 mb-0">
        <p className="small mb-0">{t("food:claiming_instructions")}</p>
        <Button
          ref={buttonRef}
          className="mt-2"
          onMouseDown={() => isPressed.turnOn()}
          onMouseUp={() => isPressed.turnOff()}
          onMouseLeave={() => isPressed.turnOff()}
          onTouchStart={() => isPressed.turnOn()}
          onTouchEnd={() => isPressed.turnOff()}
        >
          {t("food:press_and_hold")}
        </Button>
        {isPressed.isOn && (
          <div className="mt-2">
            <Spinner
              variant="primary"
              animation="grow"
              className="order-confirmation-spinner-duration"
            />
          </div>
        )}
      </Alert>
    </div>
  );
}
