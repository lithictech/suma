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

export default function FundingTransactionListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getFundingTransactions = React.useCallback(() => {
    return api.getFundingTransactions({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getFundingTransactions,
    {
      default: {},
      pickData: true,
    }
  );

  return (
    <>
      <FabAdd component={Link} href={"/funding-transaction/new"} />
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Funding Transactions"
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
