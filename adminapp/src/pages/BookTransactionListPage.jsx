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

export default function BookTransactionListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getBookTransactions = React.useCallback(() => {
    return api.getBookTransactions({
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
      <FabAdd component={Link} href={"/book-transaction/new"} />
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Book Transactions"
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
            id: "apply_at",
            label: "Apply At",
            align: "center",
            sortable: true,
            render: (c) => dayjs(c.applyAt).format("lll"),
          },
          {
            id: "amount",
            label: "Amount",
            align: "center",
            render: (c) => <Money>{c.amount}</Money>,
          },
          {
            id: "memo",
            label: "Memo",
            align: "center",
            render: (c) => c.memo,
          },
          {
            id: "category",
            label: "Category",
            align: "center",
            render: (c) => c.associatedVendorServiceCategory.name,
          },
          {
            id: "originating",
            label: "Originating",
            align: "center",
            render: (c) => (
              <AdminLink model={c.originatingLedger}>
                {c.originatingLedger.accountName}
              </AdminLink>
            ),
          },
          {
            id: "receiving",
            label: "Receiving",
            align: "center",
            render: (c) => (
              <AdminLink model={c.receivingLedger}>
                {c.receivingLedger.accountName}
              </AdminLink>
            ),
          },
        ]}
      />
    </>
  );
}
