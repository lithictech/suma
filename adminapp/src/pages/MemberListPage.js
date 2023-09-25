import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceTable from "../components/ResourceTable";
import Unavailable from "../components/Unavailable";
import { dayjs } from "../modules/dayConfig";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function MemberListPage() {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getMembers = React.useCallback(() => {
    return api.getMembers({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [order, orderBy, page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(getMembers, {
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
      title="Members"
      listResponse={listResponse}
      listLoading={listLoading}
      tableProps={{ sx: { minWidth: 650 }, size: "small" }}
      downloadUrl={api.makeUrl("/adminapi/v1/members", {
        order,
        orderBy,
        search,
        download: "csv",
      })}
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
          id: "phone",
          label: "Phone Number",
          align: "left",
          sortable: true,
          render: (c) => maskPhoneNumber("+" + c.phone),
        },
        {
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name || <Unavailable />}</AdminLink>,
        },
        {
          id: "created_at",
          label: "Registered",
          align: "left",
          sortable: true,
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
      ]}
    />
  );
}
