import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import DetailGrid from "./DetailGrid";
import Link from "./Link";
import EditIcon from "@mui/icons-material/Edit";
import { CircularProgress } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import isEmpty from "lodash/isEmpty";
import isFunction from "lodash/isFunction";
import React from "react";
import { useParams } from "react-router-dom";

export default function ResourceDetail({ apiGet, title, properties, toEdit, children }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getResource = React.useCallback(() => {
    return apiGet({ id }).catch(enqueueErrorSnackbar);
  }, [apiGet, id, enqueueErrorSnackbar]);
  const { state, loading, replaceState } = useAsyncFetch(getResource, {
    default: {},
    pickData: true,
  });
  if (children && !isFunction(children)) {
    console.error("ResourceDetail children must be a function");
    return null;
  }
  return (
    <>
      {loading && <CircularProgress />}
      {!isEmpty(state) && (
        <div>
          <DetailGrid
            title={<Title toEdit={toEdit && toEdit(state)}>{title(state)}</Title>}
            properties={properties(state)}
          />
          {children && children(state, replaceState)}
        </div>
      )}
    </>
  );
}

function Title({ toEdit, children }) {
  if (!toEdit) {
    return children;
  }
  return (
    <>
      {children}
      <IconButton href={toEdit} component={Link}>
        <EditIcon color="info" />
      </IconButton>
    </>
  );
}
