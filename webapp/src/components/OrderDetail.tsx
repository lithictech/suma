import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import SumaImage from "../components/SumaImage";
import { dt, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useErrorToast from "../state/useErrorToast";
import useScreenLoader from "../state/useScreenLoader";
import useToggle from "../state/useToggle";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import Form from "../ui/Form";
import Grid from "../ui/Grid";
import Stack from "../ui/Stack";
import Money from "../uir/Money";
import ScrollTopOnMount from "../uir/ScrollToTopOnMount";
import TODO from "./TODO.tsx";
import isEmpty from "lodash/isEmpty";
import React from "react";

interface OrderDetailProps {
  order: DetailedOrderHistory;
  setOrder: (order: DetailedOrderHistory) => void;
}

export default function OrderDetail({ order, setOrder }: OrderDetailProps) {
  return (
    <Stack col gap={3}>
      <div>
        <h2 className="mb-1">{t("food.order_serial", { serial: order.serial })}</h2>
        {dayjs(order.createdAt).format("lll")}
      </div>
      <PressAndHoldToClaim
        id={order.id}
        canClaim={order.canClaim}
        offeringDescription={order.offeringDescription}
        onOrderClaim={(o) => setOrder(o)}
      />
      <p>
        {t("food.labels.price", { price: order.customerCost })}
        {order.customerCost.cents !== order.undiscountedCost.cents && (
          <Money className="color-text-muted">{order.undiscountedCost}</Money>
        )}
        <br />
        {t("food.labels.fees_and_taxes", { fees: order.handling, taxes: order.tax })}
        <br />
        {t("food.labels.total", { total: order.total })}
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
        <TODO name="ALERT" variant="info" className="mb-0">
          <ScrollTopOnMount />
          <Stack direction="horizontal" gap={3}>
            {t("food.order_for_claimed_on", {
              offeringDescription: order.offeringDescription,
              fulfilledAt: dayjs(order.fulfilledAt).format("lll"),
            })}
            <div className="ms-auto">
              <AnimatedCheckmark />
            </div>
          </Stack>
        </TODO>
      )}
      <SumaImage image={order.image} w={350} height={150} cover />
      <hr className="my-0" />
      {t("food.labels.items_count", { itemCount: order.items.length })}
      <Grid columns={2}>
        {order.items.map(({ name, description, customerPrice, quantity }, i: number) => (
          <React.Fragment key={i}>
            <div>
              {dt(name)}
              <br />
              {t("food.price_times_quantity", {
                price: customerPrice,
                quantity,
              })}
            </div>
            <div>{dt(description)}</div>
          </React.Fragment>
        ))}
      </Grid>
    </Stack>
  );
}

interface FulfillmentOptionProps {
  order: DetailedOrderHistory;
  onOrderUpdated: (order: DetailedOrderHistory) => void;
}

function FulfillmentOption({ order, onOrderUpdated }: FulfillmentOptionProps) {
  const editing = useToggle(false);
  const screenLoader = useScreenLoader();
  const [optionId, setOptionId] = React.useState(0);
  const { showErrorToast } = useErrorToast();

  if (isEmpty(order.fulfillmentOptionsForEditing)) {
    if (!order.fulfillmentOption) {
      // No options, and nothing is selected, so nothing to show
      return null;
    }
    // No options, but something is selected, so show it
    return (
      <div>
        <h6 className="fw-bold">{dt(order.fulfillmentConfirmation)}</h6>
        <span>{dt(order.fulfillmentOption.description)}</span>
      </div>
    );
  }

  if (editing.isOff) {
    return (
      <span>
        <h6 className="fw-bold lh-lg">
          {dt(order.fulfillmentConfirmation)}
          {order.fulfillmentOptionEditable && (
            <Button
              variant="text"
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
          <span className="text-secondary">{t("food.no_option_chosen")}</span>
        )}
      </span>
    );
  }
  function updateFulfillment(e: React.FormEvent) {
    e.preventDefault();
    screenLoader.turnOn();
    api
      .updateOrderFulfillment({ orderId: order.id, optionId: optionId })
      .then((r) => {
        editing.turnOff();
        screenLoader.turnOff();
        onOrderUpdated(r.data);
      })
      .catch((e: any) => {
        screenLoader.turnOff();
        showErrorToast(e, { extract: true });
      });
  }
  const chosenFulfillmentValid = order.fulfillmentOptionsForEditing.some(
    ({ id }) => id === optionId
  );

  return (
    <Form noValidate>
      <TODO x={updateFulfillment} y={chosenFulfillmentValid} />
      {/*<FormGroup>*/}
      {/*  <h6 className="fw-bold lh-lg">{order.fulfillmentConfirmation}</h6>*/}
      {/*  {order.fulfillmentOptionsForEditing.map((fo) => (*/}
      {/*    <FormCheck*/}
      {/*      key={fo.id}*/}
      {/*      id={String(fo.id)}*/}
      {/*      name={fo.description}*/}
      {/*      type="radio"*/}
      {/*      label={fo.description}*/}
      {/*      checked={optionId === fo.id}*/}
      {/*      onChange={() => setOptionId(fo.id)}*/}
      {/*    />*/}
      {/*  ))}*/}
      {/*</FormGroup>*/}
      {/*<FormSaveCancel*/}
      {/*  saveDisabled={!chosenFulfillmentValid}*/}
      {/*  className="mt-2"*/}
      {/*  onCancel={editing.turnOff}*/}
      {/*  onSave={updateFulfillment}*/}
      {/*/>*/}
    </Form>
  );
}

interface PressAndHoldToClaimProps {
  id: number;
  canClaim: boolean;
  offeringDescription: string;
  onOrderClaim: (order: DetailedOrderHistory) => void;
}

function PressAndHoldToClaim({
  id,
  canClaim,
  offeringDescription,
  onOrderClaim,
}: PressAndHoldToClaimProps) {
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
      .catch((e: any) => {
        screenLoader.turnOff();
        showErrorToast(e, { extract: true });
      });
  };
  return (
    <TODO
      handle={handleOrderClaim}
      instructions={t("food.claiming_instructions", {
        offeringDescription: offeringDescription,
      })}
      in2={t("food.press_and_hold")}
    />
  );
}
