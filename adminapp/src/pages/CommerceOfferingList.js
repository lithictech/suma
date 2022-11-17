import api from "../api";
import AdminLink from "../components/AdminLink";
import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function CommerceOfferingList() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getBookTransactions = React.useCallback(() => {
    return api.getCommerceOfferings({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);

  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getBookTransactions,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <>
      {/*<FabAdd component={Link} href={"/commerce_offering/new"} />*/}
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Commerce Offerings"
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
            sortable: true,
            render: (c) => <AdminLink model={c}>{c.description}</AdminLink>,
          },
          {
            id: "product_amount",
            label: "Product Amount",
            align: "center",
            render: (c) => c.productsAmount,
          },
          {
            id: "closes_at",
            label: "Closing Date",
            align: "center",
            render: (c) => dayjs(c.closesAt).format("lll"),
          },
        ]}
      />
    </>
  );
}
