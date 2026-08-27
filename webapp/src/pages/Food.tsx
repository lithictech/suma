import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import TODO from "../components/TODO.tsx";
import VendibleCard from "../components/VendibleCard";
import WaitingList from "../components/WaitingList";
import { t } from "../localization";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import Stack from "../ui/Stack";
import isEmpty from "lodash/isEmpty";

export default function Food() {
  const {
    state: offerings,
    loading: offeringsLoading,
    error: offeringsError,
  } = useAsyncFetch<{ items: Offering[] }>(api.getCommerceOfferings, {
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
      <TODO>
        <PageLoader buffered />
      </TODO>
    );
  }
  const { items } = offerings;
  if (isEmpty(items)) {
    return (
      <TODO>
        <WaitingList title={t("food.title")} text={t("food.intro")} survey={surveySpec} />
        <OrderHistoryLink />
      </TODO>
    );
  }
  return (
    <>
      <LayoutContainer gutters>
        <h4 className="mb-3">{t("food.current_offerings")}</h4>
        <Stack gap={3}>
          {items.map((it) => (
            <VendibleCard key={it.id} {...it} />
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
          <Button variant="outline" href="/order-history">
            <i className="bi bi-bag-check-fill me-2"></i>
            {t("food.order_history_title")}
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
      labelKey: "surveys.member_type.label",
      format: "radio" as const,
      answers: [
        { key: "community", labelKey: "surveys.member_type.community" },
        { key: "for_profit", labelKey: "surveys.member_type.for_profit" },
        { key: "government", labelKey: "surveys.member_type.government" },
        { key: "non_profit", labelKey: "surveys.member_type.non_profit" },
        { key: "philanthropy", labelKey: "surveys.member_type.philanthropy" },
      ],
    },
    {
      key: "food_shopping",
      labelKey: "surveys.food_options.label",
      format: "checkbox" as const,
      answers: [
        { key: "albertsons", labelKey: "surveys.food_options.albertsons" },
        { key: "fred_meyer", labelKey: "surveys.food_options.fred_meyer" },
        { key: "safeway", labelKey: "surveys.food_options.safeway" },
        { key: "winco", labelKey: "surveys.food_options.winco" },
        { key: "market", labelKey: "surveys.food_options.market" },
      ],
    },
    {
      key: "learn_more",
      labelKey: "surveys.food_learn_more.label",
      format: "checkbox" as const,
      answers: [
        {
          key: "connect_resources",
          labelKey: "surveys.food_learn_more.connect_resources",
        },
        {
          key: "grant_support",
          labelKey: "surveys.food_learn_more.grant_support",
        },
        { key: "partner", labelKey: "surveys.food_learn_more.partner" },
        { key: "save", labelKey: "surveys.food_learn_more.save" },
      ],
    },
  ],
};
