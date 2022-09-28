import api from "../api";
import ResourceTable from "../components/ResourceTable";
import Unavailable from "../components/Unavailable";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";
import { formatPhoneNumber } from "react-phone-number-input";
import { Link } from "react-router-dom";

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
      onParamsChange={setListQueryParams}
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <Link to={"/member/" + c.id}>{c.id}</Link>,
        },
        {
          id: "phone",
          label: "Phone Number",
          align: "center",
          sortable: true,
          render: (c) => formatPhoneNumber("+" + c.phone),
        },
        {
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <Link to={"/member/" + c.id}>{c.name || <Unavailable />}</Link>,
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
