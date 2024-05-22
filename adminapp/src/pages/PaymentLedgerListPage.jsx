import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function PaymentLedgerListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getPaymentLedgers = React.useCallback(() => {
    return api.getPaymentLedgers({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(getPaymentLedgers, {
    default: {},
    pickData: true,
  });

  return (
    <ResourceTable
      page={page}
      perPage={perPage}
      search={search}
      order={order}
      orderBy={orderBy}
      title="Payment Ledgers"
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
          id: "name",
          label: "Name",
          sortable: true,
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "member",
          label: "Member",
          render: (c) =>
            c.isPlatformAccount ? (
              "(Platform)"
            ) : (
              <AdminLink model={c.member}>{c.member?.name}</AdminLink>
            ),
        },
        {
          id: "balance",
          label: "Balance",
          render: (c) => <Money>{c.balance}</Money>,
        },
      ]}
    />
  );
}
