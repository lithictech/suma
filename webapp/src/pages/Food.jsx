import api from "../api";
import foodHeaderImage from "../assets/images/onboarding-food.jpg";
import ErrorScreen from "../components/ErrorScreen";
import FeaturePageHeader from "../components/FeaturePageHeader";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import VendibleCard from "../components/VendibleCard";
import WaitingList from "../components/WaitingList";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUser from "../state/useUser";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";

export default function Food() {
  const {
    state: offerings,
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
  if (offeringsLoading) {
    return (
      <FeaturePageHeader imgSrc={foodHeaderImage} imgAlt={t("food:local_food_stand")}>
        <PageLoader buffered />
      </FeaturePageHeader>
    );
  }
  const { items } = offerings;
  if (isEmpty(items)) {
    return (
      <FeaturePageHeader imgSrc={foodHeaderImage} imgAlt={t("food:local_food_stand")}>
        <WaitingList title={t("food:title")} text={t("food:intro")} survey={surveySpec} />
        <OrderHistoryLink />
      </FeaturePageHeader>
    );
  }
  return (
    <>
      <FeaturePageHeader imgSrc={foodHeaderImage} imgAlt={t("food:local_food_stand")}>
        <h2>{t("food:title")}</h2>
        <p className="mb-0">{t("food:intro")}</p>
      </FeaturePageHeader>
      <hr className="my-4" />
      <LayoutContainer gutters>
        <h4 className="mb-3">{t("food:current_offerings")}</h4>
        <Stack gap={3}>
          {items.map((o) => (
            <VendibleCard key={o.id} {...o.vendible} />
          ))}
        </Stack>
      </LayoutContainer>
      <OrderHistoryLink />
    </>
  );
}

function OrderHistoryLink() {
  const { user } = useUser();
  if (!user.hasOrderHistory) {
    return null;
  }
  return (
    <>
      <hr className="my-4" />
      <LayoutContainer gutters>
        <div className="button-stack">
          <Button variant="outline-primary" href="/order-history" as={RLink}>
            <i className="bi bi-bag-check-fill me-2"></i>
            {t("food:order_history_title")}
          </Button>
        </div>
      </LayoutContainer>
    </>
  );
}

const surveySpec = {
  topic: "food_waitlist",
  questions: [
    {
      key: "entity_type",
      labelKey: "surveys:member_type:label",
      format: "radio",
      answers: [
        { key: "community", labelKey: "surveys:member_type:community" },
        { key: "for_profit", labelKey: "surveys:member_type:for_profit" },
        { key: "government", labelKey: "surveys:member_type:government" },
        { key: "non_profit", labelKey: "surveys:member_type:non_profit" },
        { key: "philanthropy", labelKey: "surveys:member_type:philanthropy" },
      ],
    },
    {
      key: "food_shopping",
      labelKey: "surveys:food_options:label",
      format: "checkbox",
      answers: [
        { key: "albertsons", labelKey: "surveys:food_options:albertsons" },
        { key: "fred_meyer", labelKey: "surveys:food_options:fred_meyer" },
        { key: "safeway", labelKey: "surveys:food_options:safeway" },
        { key: "winco", labelKey: "surveys:food_options:winco" },
        { key: "market", labelKey: "surveys:food_options:market" },
      ],
    },
    {
      key: "learn_more",
      labelKey: "surveys:food_learn_more:label",
      format: "checkbox",
      answers: [
        {
          key: "connect_resources",
          labelKey: "surveys:food_learn_more:connect_resources",
        },
        {
          key: "grant_support",
          labelKey: "surveys:food_learn_more:grant_support",
        },
        { key: "partner", labelKey: "surveys:food_learn_more:partner" },
        { key: "save", labelKey: "surveys:food_learn_more:save" },
      ],
    },
  ],
};
