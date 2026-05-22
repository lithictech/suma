import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import useToggle from "../shared/react/useToggle";
import Link from "./Link";
import "./RelatedList.css";
import SimpleTable from "./SimpleTable";
import ListAltIcon from "@mui/icons-material/ListAlt";
import { Card, CardContent, Chip, Stack } from "@mui/material";
import Button from "@mui/material/Button";
import Typography from "@mui/material/Typography";
import clsx from "clsx";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
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
  const [loadAll, setLoadAll] = React.useState(false);

  const { canWriteResource } = useRoleAccess();

  const loadNextPage = React.useCallback(() => {
    setPageLoading(true);
    api
      .post(latestCollection.url, { page: nextPage, pageSize: PAGE_SIZE })
      .then((r) => {
        setAllRows([...allRows, r.data.items]);
        setLatestCollection(r.data);
        setNextPage(nextPage + 1);
        if (!r.data.hasMore) {
          setPageLoading(false);
          return;
        }
        if (loadAll) {
          return loadNextPage();
        }
        setPageLoading(false);
      })
      .catch((e) => {
        enqueueErrorSnackbar(e);
        setPageLoading(false);
        setLoadAll(false);
      });
  }, []);
  function handleLoadMore(e) {
    e.preventDefault();
    loadNextPage();
  }
  function handleLoadAll(e) {
    e.preventDefault();
    setLoadAll(true);
    handleLoadMore(e);
  }
  console.log(collection);
  // const topRef = React.useRef();

  // if (pushLeft === undefined) {
  //   pushLeft = headers?.length <= 2;
  // }
  const addNew = Boolean(addNewLink || onAddNewClick) && canWriteResource(addNewRole);

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
        <Stack direction="row" sx={{ marginTop: 1, justifyContent: "center" }}>
          <Button variant="link" disabled={disableLoadButtons} onClick={handleLoadMore}>
            Load More
          </Button>
          <Button variant="link" disabled={disableLoadButtons} onClick={handleLoadAll}>
            Load All
          </Button>
        </Stack>
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
