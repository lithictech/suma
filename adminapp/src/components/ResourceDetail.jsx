import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import { resourceEditRoute } from "../modules/resourceRoutes";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import DetailGrid from "./DetailGrid";
import Link from "./Link";
import EditIcon from "@mui/icons-material/Edit";
import { CircularProgress } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import isEmpty from "lodash/isEmpty";
import isFunction from "lodash/isFunction";
import startCase from "lodash/startCase";
import React from "react";
import { useParams } from "react-router-dom";

export default function ResourceDetail({
  resource,
  apiGet,
  title,
  properties,
  canEdit,
  children,
}) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { canWriteResource } = useRoleAccess();
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
  title = title || ((m) => `${startCase(resource)} ${m.id}`);
  return (
    <>
      {loading && <CircularProgress />}
      {!isEmpty(state) && (
        <div>
          <DetailGrid
            title={
              <Title
                toEdit={
                  canEdit &&
                  canWriteResource(resource) &&
                  resourceEditRoute(resource, state)
                }
              >
                {title(state)}
              </Title>
            }
            properties={properties(state, replaceState)}
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
