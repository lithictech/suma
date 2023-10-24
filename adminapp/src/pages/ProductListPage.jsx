import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function ProductListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getCommerceProducts = React.useCallback(() => {
    return api.getCommerceProducts({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);

  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getCommerceProducts,
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
      title="Products"
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
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "vendor",
          label: "Vendor",
          align: "left",
          render: (c) => c.vendor.name,
        },
      ]}
    />
  );
}
