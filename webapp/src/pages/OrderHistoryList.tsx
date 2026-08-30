import api from "../api";
import AsyncContent from "../components/AsyncContent.tsx";
import OrderList from "../components/OrderList.tsx";
import { t } from "../localization";
import useNavigate from "../routing/useNavigate";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser.ts";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import find from "lodash/find";

export default function OrderHistoryList() {
  const { user } = useUser();
  const {
    state: orderHistory,
    loading,
    error,
  } = useAsyncFetch<OrderHistoryCollection>(api.getOrderHistory, {
    default: {} as OrderHistoryCollection,
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
      <AsyncContent loading={loading} error={error}>
        {() => (
          <OrderList
            user={user!}
            loading={loading}
            orders={orderHistory?.items}
            onNavigate={handleNavigate}
          />
        )}
      </AsyncContent>
    </Page>
  );
}
