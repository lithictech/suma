import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import useDebugEffect from "../shared/react/useDebugEffect";
import Link from "./Link";
import "./RelatedList.css";
import SimpleTable from "./SimpleTable";
import ListAltIcon from "@mui/icons-material/ListAlt";
import { Card, CardContent, Chip, Stack } from "@mui/material";
import Button from "@mui/material/Button";
import Typography from "@mui/material/Typography";
import isEmpty from "lodash/isEmpty";
import React from "react";

const PAGE_SIZE = 100;

export default function RelatedListRemote({
  title,
  headers,
  pushLeft,
  addNewLabel,
  addNewLink,
  addNewRole,
  emptyState,
  cardProps,
  className,
  onAddNewClick,
  collection,
  ...rest
}) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [allRows, setAllRows] = React.useState(collection.items);
  const [latestCollection, setLatestCollection] = React.useState(collection);
  const [nextPage, setNextPage] = React.useState(1);
  const [pageLoading, setPageLoading] = React.useState(false);

  const { canWriteResource } = useRoleAccess();

  const loadNextPage = React.useCallback(
    ({ loadAll, page = nextPage, rows = allRows }) => {
      setPageLoading(true);
      api
        .get(latestCollection.url, { page, pageSize: PAGE_SIZE })
        .then((r) => {
          // Replace page 1 since we only have a partial list initially.
          const newRows = page === 1 ? r.data.items : [...rows, ...r.data.items];
          setAllRows(newRows);
          setLatestCollection(r.data);
          setNextPage(page + 1);
          if (!r.data.hasMore) {
            setPageLoading(false);
            return;
          }
          if (loadAll) {
            return loadNextPage({ loadAll, page: page + 1, rows: newRows });
          }
          setPageLoading(false);
        })
        .catch((e) => {
          enqueueErrorSnackbar(e);
          setPageLoading(false);
        });
    },
    [allRows, enqueueErrorSnackbar, latestCollection.url, nextPage]
  );

  function handleLoadMore(e) {
    e.preventDefault();
    loadNextPage({ loadAll: false });
  }

  function handleLoadAll(e) {
    e.preventDefault();
    loadNextPage({ loadAll: true });
  }

  if (pushLeft === undefined) {
    pushLeft = headers?.length <= 2;
  }
  const addNew = Boolean(addNewLink || onAddNewClick) && canWriteResource(addNewRole);

  useDebugEffect(() => api.get(latestCollection.url, { page: 1, pageSize: 2 }), {
    once: true,
  });

  if (!collection.totalCount && !addNew && !emptyState) {
    return null;
  }

  const disableLoadButtons = pageLoading || !latestCollection.hasMore;

  return (
    <Card {...cardProps}>
      <CardContent sx={{ paddingBottom: "0 !important", marginBottom: 1 }}>
        {title && (
          <Typography variant="h6" gutterBottom>
            {title} <ListCount count={latestCollection.totalCount} />
          </Typography>
        )}
        {addNew && (
          <Link to={addNewLink} onClick={onAddNewClick}>
            <ListAltIcon sx={{ verticalAlign: "middle", marginRight: "5px" }} />
            {addNewLabel}
          </Link>
        )}
        {isEmpty(allRows) ? (
          emptyState
        ) : (
          <SimpleTable
            tableProps={{ size: "small" }}
            headers={headers}
            pushLeft={pushLeft}
            rows={allRows}
            className={className}
            {...rest}
          />
        )}
        {collection.hasMore && (
          <Stack direction="row" sx={{ marginTop: 1, justifyContent: "center" }} gap={2}>
            <Button size="small" disabled={disableLoadButtons} onClick={handleLoadMore}>
              Load Page {latestCollection.hasMore ? nextPage : ""}
            </Button>
            <Button size="small" disabled={disableLoadButtons} onClick={handleLoadAll}>
              Load All {latestCollection.totalCount}
            </Button>
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}

function ListCount({ count }) {
  if (!count) {
    return null;
  }
  return (
    <Chip
      label={count}
      variant="outlined"
      size="small"
      color="secondary"
      sx={{ marginLeft: 0.5 }}
    />
  );
}
