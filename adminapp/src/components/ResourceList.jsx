import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResourceTable from "../components/ResourceTable";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import React from "react";

export default function ResourceList({ apiList, toCreate, title, canSearch, columns }) {
  const { page, perPage, search, order, orderBy, setListQueryParams } =
    useListQueryControls();

  const getList = React.useCallback(() => {
    return apiList({
      page: page + 1,
      perPage,
      search,
      orderBy,
      orderDirection: order,
    });
  }, [apiList, order, orderBy, page, perPage, search]);

  const { state: listResponse, loading: listLoading } = useAsyncFetch(getList, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {toCreate && <FabAdd component={Link} href={toCreate} />}
      <ResourceTable
        page={page}
        perPage={perPage}
        search={canSearch ? search : undefined}
        order={order}
        orderBy={orderBy}
        title={title}
        listResponse={listResponse}
        listLoading={listLoading}
        tableProps={{ sx: { minWidth: 650 }, size: "small" }}
        onParamsChange={setListQueryParams}
        columns={columns}
      />
    </>
  );
}
