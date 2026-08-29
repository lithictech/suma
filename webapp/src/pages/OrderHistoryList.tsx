import api from "../api";
import AsyncContent from "../components/AsyncContent.tsx";
import OrderList from "../components/OrderList.tsx";
import TODO from "../components/TODO.tsx";
import { t } from "../localization";
import useNavigate from "../routing/useNavigate";
import useAsyncFetch from "../state/useAsyncFetch";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import find from "lodash/find";

export default function OrderHistoryList() {
  // const { user } = useUser();
  const {
    state: orderHistory,
    loading,
    error,
  } = useAsyncFetch<OrderHistoryCollection>(api.getOrderHistory, {
    default: {} as OrderHistoryCollection,
    pickData: true,
  });
  const navigate = useNavigate();
  function handleNavigate(order: SimpleOrderHistory) {
    const detailed = find(orderHistory.detailedOrders, { id: order.id });
    const opts = detailed ? { state: { order: detailed } } : {};
    navigate(["/order/:id", { id: order.id }], opts);
  }
  return (
    <Page appNav>
      <PageHeader title={t("food.order_history_title")} back="/food" />
      <TODO>
        {`user.unclaimedOrdersCount > 0 && (
        <SeeAlsoAlert
          variant="success"
          label={t("dashboard.claim_orders")}
          iconClass="bi-bag-check-fill"
          alertClass="solo-alert"
          show
          to="/unclaimed-orders"
        />
      )`}
      </TODO>
      <AsyncContent loading={loading} error={error}>
        <OrderList
          loading={loading}
          orders={orderHistory?.items}
          onNavigate={handleNavigate}
        />
      </AsyncContent>
    </Page>
  );
}
