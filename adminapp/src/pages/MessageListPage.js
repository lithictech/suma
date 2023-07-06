import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import { dayjs } from "../modules/dayConfig";
import dateFormat from "../shared/dateFormat";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function MessageListPage() {
  const { page, perPage, order, orderBy, setListQueryParams } = useListQueryControls();

  const getMessageDeliveries = React.useCallback(() => {
    return api.getMessageDeliveries({
      page: page + 1,
      perPage,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage]);

  const { state: listResponse, loading: listLoading } = useAsyncFetch(
    getMessageDeliveries,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <ResourceTable
      disableSearch
      page={page}
      perPage={perPage}
      order={order}
      orderBy={orderBy}
      title="Messages"
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
          id: "sent_at",
          label: "Sent",
          align: "left",
          sortable: true,
          render: (c) => dateFormat(c.sentAt, "lll"),
        },
        {
          id: "to",
          label: "To",
          align: "left",
          render: (c) =>
            c.recipient ? (
              <AdminLink model={c.recipient}>{c.recipient.name}</AdminLink>
            ) : (
              c.to
            ),
        },
      ]}
    />
  );
}
