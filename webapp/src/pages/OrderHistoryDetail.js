import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FormSaveCancel from "../components/FormSaveCancel";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { md, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { useErrorToast } from "../state/useErrorToast";
import { useScreenLoader } from "../state/useScreenLoader";
import { LayoutContainer } from "../state/withLayout";
import _ from "lodash";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Form from "react-bootstrap/Form";
import { useLocation, useParams } from "react-router-dom";

export default function OrderHistoryDetail() {
  const { id } = useParams();
  const location = useLocation();
  const getOrderDetails = React.useCallback(() => api.getOrderDetails({ id }), [id]);
  const { state, replaceState, loading, error } = useAsyncFetch(getOrderDetails, {
    default: {},
    pickData: true,
    pullFromState: "order",
    location,
  });
  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading) {
    return <PageLoader />;
  }
  return (
    <>
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back="/order-history" />
      </LayoutContainer>
      <LayoutContainer gutters>
        <Stack gap={3}>
          <div>
            <h2 className="mb-1">{t("food:order_serial", { serial: state.serial })}</h2>
            {dayjs(state.createdAt).format("lll")}
          </div>
          <p className="mb-0">
            {t("food:labels:price", { price: state.customerCost })}
            <Money as="del" className="text-secondary ms-2">
              {state.undiscountedCost}
            </Money>
            <br />
            {t("food:labels:fees_and_taxes", { fees: state.handling, taxes: state.tax })}
            <br />
            {t("food:labels:total", { total: state.total })}
            {state.fundingTransactions.map(({ label, amount }) => (
              <React.Fragment key={label}>
                <br />
                {label}: <Money>{amount}</Money>
              </React.Fragment>
            ))}
            <br />
          </p>
          <FulfillmentOption
            order={state}
            onOrderUpdated={(o) => replaceState(o)}
          ></FulfillmentOption>
          <SumaImage
            image={state.image}
            w={350}
            height={150}
            className="rounded responsive-wide-image"
          />
          <hr className="my-0" />
          <Card.Text className="h4 mb-0">
            {t("food:labels:items_count", { itemCount: state.items.length })}
          </Card.Text>
          {state.items.map(({ name, description, customerPrice, quantity }, i) => (
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
      </LayoutContainer>
    </>
  );
}

function FulfillmentOption({ order, onOrderUpdated }) {
  const editing = useToggle(false);
  const screenLoader = useScreenLoader();
  const [optionId, setOptionId] = React.useState(0);
  const { showErrorToast } = useErrorToast();

  if (_.isEmpty(order.fulfillmentOptionsForEditing)) {
    return <span>{order.fulfillmentOption.description}</span>;
  }

  if (editing.isOff) {
    return (
      <span>
        {order.fulfillmentOption.description}
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
        <h5>{t("food:fulfillment_title")}</h5>
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
