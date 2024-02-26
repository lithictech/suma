import api from "../api";
import AdminLink from "../components/AdminLink";
import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function PaymentTriggerListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getPaymentTriggers = React.useCallback(() => {
    return api.getPaymentTriggers({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getPaymentTriggers,
    {
      default: {},
      pickData: true,
    }
  );

  return (
    <>
      <FabAdd component={Link} href={"/payment-trigger/new"} />
      <ResourceTable
        page={page}
        perPage={perPage}
        search={search}
        order={order}
        orderBy={orderBy}
        title="Payment Triggers"
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
            id: "label",
            label: "Label",
            sortable: true,
            render: (c) => <AdminLink model={c}>{c.label}</AdminLink>,
          },
          {
            id: "active_during",
            label: "Active During",
            sortable: true,
            render: (c) =>
              `${dayjs(c.activeDuringBegin).format("ll")} - ${dayjs(
                c.activeDuringEnd
              ).format("ll")}`,
          },
        ]}
      />
    </>
  );
}
