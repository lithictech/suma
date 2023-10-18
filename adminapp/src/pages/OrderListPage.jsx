import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function OrderListPage() {
  const { page, perPage, order, orderBy, setListQueryParams } = useListQueryControls();

  const getCommerceOrders = React.useCallback(() => {
    return api.getCommerceOrders({
      page: page + 1,
      perPage,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage]);

  const { state: listResponse, loading: listLoading } = useAsyncFetch(getCommerceOrders, {
    default: {},
    pickData: true,
  });
  return (
    <ResourceTable
      disableSearch
      page={page}
      perPage={perPage}
      order={order}
      orderBy={orderBy}
      title="Orders"
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
          align: "left",
          sortable: true,
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => <AdminLink model={c.member}>{c.member.name}</AdminLink>,
        },
        {
          id: "items",
          label: "Items",
          align: "left",
          render: (c) => c.totalItemCount,
        },
        {
          id: "status",
          label: "Status",
          align: "left",
          render: (c) => c.statusLabel,
        },
      ]}
    />
  );
}
