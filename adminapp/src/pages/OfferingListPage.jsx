import api from "../api";
import AdminLink from "../components/AdminLink";
import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function OfferingListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getCommerceOfferings = React.useCallback(() => {
    return api.getCommerceOfferings({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);

  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getCommerceOfferings,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <>
      <FabAdd component={Link} href={"/offerings/new"} />
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Offerings"
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
            id: "description",
            label: "Description",
            align: "left",
            render: (c) => <AdminLink model={c}>{c.description}</AdminLink>,
          },
          {
            id: "orders",
            label: "Order Count",
            align: "center",
            render: (c) => c.orderCount,
          },
          {
            id: "product_amount",
            label: "Product Count",
            align: "center",
            render: (c) => c.productCount,
          },
          {
            id: "opens_at",
            label: "Opens",
            align: "center",
            render: (c) => dayjs(c.opensAt).format("lll"),
          },
          {
            id: "closes_at",
            label: "Closes",
            align: "center",
            render: (c) => dayjs(c.closesAt).format("lll"),
          },
        ]}
      />
    </>
  );
}
