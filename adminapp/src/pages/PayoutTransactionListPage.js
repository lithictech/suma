import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function PayoutTransactionListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getPayoutTransactions = React.useCallback(() => {
    return api.getPayoutTransactions({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getPayoutTransactions,
    {
      default: {},
      pickData: true,
    }
  );

  return (
    <>
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Payout Transactions"
        listResponse={listResponse}
        listLoading={listLoading}
        tableProps={{ sx: { minWidth: 650 }, size: "small" }}
        onParamsChange={setListQueryParams}
        columns={[
          {
            id: "id",
            label: "ID",
            align: "center",
            sortable: true,
            render: (c) => <AdminLink model={c} />,
          },
          {
            id: "created_at",
            label: "Created",
            align: "center",
            sortable: true,
            render: (c) => dayjs(c.createdAt).format("lll"),
          },
          {
            id: "amount",
            label: "Amount",
            align: "center",
            render: (c) => <Money>{c.amount}</Money>,
          },
          {
            id: "status",
            label: "Status",
            align: "center",
            render: (c) => c.status,
          },
          {
            id: "classification",
            label: "Type",
            align: "center",
            render: (c) => c.classification,
          },
          {
            id: "originating",
            label: "Originating",
            align: "center",
            render: (c) => (
              <AdminLink model={c.originatingPaymentAccount}>
                {c.originatingPaymentAccount.displayName}
              </AdminLink>
            ),
          },
        ]}
      />
    </>
  );
}
