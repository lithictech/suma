import api from "../api";
import foodHeaderImage from "../assets/images/onboarding-food.jpg";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import VendibleCard from "../components/VendibleCard";
import WaitingListPage from "../components/WaitingListPage";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
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
    return <PageLoader buffered />;
  }
  const { items } = offerings;
  return (
    <>
      <IntroHeader offeringItems={items} />
      <hr className="my-4" />
      <LayoutContainer gutters>
        {!isEmpty(items) ? (
          <>
            <h4 className="mb-3">{t("food:current_offerings")}</h4>
            <Stack gap={3}>
              {items.map((o) => (
                <VendibleCard key={o.id} {...o.vendible} />
              ))}
            </Stack>
          </>
        ) : (
          <p>{t("food:no_offerings")}</p>
        )}
      </LayoutContainer>
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
  );
}

function IntroHeader({ offeringItems }) {
  if (isEmpty(offeringItems)) {
    return (
      <WaitingListPage
        feature="food"
        imgSrc={foodHeaderImage}
        imgAlt={t("food:title")}
        title={t("food:title")}
        text={<p>{t("food:intro")}</p>}
      />
    );
  }
  return (
    <>
      <img src={foodHeaderImage} alt={t("food:title")} className="thin-header-image" />
      <LayoutContainer top gutters>
        <h2>{t("food:title")}</h2>
        <p className="mb-0">{t("food:intro")}</p>
      </LayoutContainer>
    </>
  );
}
