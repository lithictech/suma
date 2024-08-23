import api from "../api";
import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResourceTable from "../components/ResourceTable";
import useRoleAccess from "../hooks/useRoleAccess";
import pluralize from "../modules/pluralize";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import startCase from "lodash/startCase";
import React from "react";

export default function ResourceList({
  resource,
  apiList,
  toCreate,
  title,
  canSearch,
  columns,
  csvDownloadUrl,
}) {
  const { canWriteResource } = useRoleAccess();
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

  title = title || `${pluralize(startCase(resource))}`;

  let downloadUrl = null;
  if (csvDownloadUrl) {
    downloadUrl = api.makeUrl("/adminapi/v1/members", {
      order,
      orderBy,
      search,
      download: "csv",
    });
  }

  return (
    <>
      {canWriteResource(resource) && toCreate && (
        <FabAdd component={Link} href={toCreate} />
      )}
      <ResourceTable
        page={page}
        perPage={perPage}
        search={canSearch ? search : undefined}
        disableSearch={!canSearch}
        order={order}
        orderBy={orderBy}
        title={title}
        listResponse={listResponse}
        listLoading={listLoading}
        tableProps={{ sx: { minWidth: 650 }, size: "small" }}
        onParamsChange={setListQueryParams}
        columns={columns}
        downloadUrl={downloadUrl}
      />
    </>
  );
}
