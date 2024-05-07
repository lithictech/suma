import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function PlatformLedgerListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getPlatformLedgers = React.useCallback(() => {
    return api.getPlatformLedgers({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getPlatformLedgers,
    {
      default: {},
      pickData: true,
    }
  );

  return (
    <ResourceTable
      page={page}
      perPage={perPage}
      search={search}
      order={order}
      orderBy={orderBy}
      title="Platform Account Ledgers"
      listResponse={listResponse}
      listLoading={listLoading}
      tableProps={{ sx: { minWidth: 650 }, size: "small" }}
      onParamsChange={setListQueryParams}
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "created_at",
          label: "Created At",
          align: "center",
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
        {
          id: "name",
          label: "Name",
          render: (c) => <AdminLink model={c}>{c.label}</AdminLink>,
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
