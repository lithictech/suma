import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import invokeIfFunc from "../modules/invokeIfFunc";
import { resourceEditRoute, resourceListRoute } from "../modules/resourceRoutes";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import AdminLink from "./AdminLink";
import BackTo from "./BackTo";
import DetailGrid from "./DetailGrid";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import {
  Box,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Stack,
} from "@mui/material";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";
import isEmpty from "lodash/isEmpty";
import isFunction from "lodash/isFunction";
import startCase from "lodash/startCase";
import React from "react";
import { useNavigate, useParams } from "react-router-dom";

/**
 * @param {string} resource Name of the resource type.
 * @param {function} apiGet Api method to get the resource.
 * @param {boolean|function} canEdit If true, or evaluates to true (called with resource state),
 *   show an edit icon.
 * @param {function=} apiDelete Api method to delete the resource.
 *   If given, show a 'delete' icon unless canDelete is false.
 *   Navigate back to the created-resource-admin header or the list for the resource type.
 * @param {function=} apiSoftDelete Api method to soft delete the resource.
 *   Stays on the page and use the response as the new resource version.
 * @param {boolean|function} canDelete If true, or evaluates to true (called with resource state),
 *   show the delete icon.
 * @param {function|string} title
 * @param {function} properties Called with the resource state and returns the property pairs (label/value).
 * @param {function|string} backTo Where clicking the 'back' icon goes.
 *   Use BackTo.BACK to use the router 'back' rather than a link.
 * @param children
 * @constructor
 */
export default function ResourceDetail({
  resource,
  apiDelete,
  apiSoftDelete,
  apiGet,
  title,
  properties,
  canEdit,
  canDelete,
  backTo,
  children,
}) {
  const [rerenderKey, setRerenderKey] = React.useState(Date.now());
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { canWriteResource } = useRoleAccess();
  const navigate = useNavigate();
  let { id } = useParams();
  id = Number(id);

  const getResource = React.useCallback(() => {
    return apiGet({ id }).catch(enqueueErrorSnackbar);
  }, [apiGet, id, enqueueErrorSnackbar]);

  const { state, loading, replaceState } = useAsyncFetch(getResource, {
    default: {},
    pickData: true,
  });

  const handleDelete = React.useCallback(() => {
    if (apiDelete) {
      return apiDelete({ id })
        .then(api.followRedirect(navigate))
        .then((r) => r !== null && navigate(resourceListRoute(resource)));
    }
    return apiSoftDelete({ id }).then((r) => {
      replaceState(r.data);
      setRerenderKey(Date.now());
    });
  }, [apiDelete, navigate, apiSoftDelete, replaceState, id, resource]);

  if (children && !isFunction(children)) {
    console.error("ResourceDetail children must be a function");
    return null;
  }
  title = title || ((m) => `${startCase(resource)} ${m.id}`);

  if (loading) {
    return <CircularProgress />;
  }
  if (isEmpty(state)) {
    return null;
  }
  let toEdit = canWriteResource(resource) && invokeIfFunc(canEdit, state);
  if (toEdit && typeof toEdit !== "string") {
    toEdit = resourceEditRoute(resource, state);
  }
  canDelete = canDelete ? invokeIfFunc(canDelete, state) : Boolean(apiDelete);

  const backToVal =
    backTo === BackTo.BACK
      ? BackTo.BACK
      : invokeIfFunc(backTo, state) || resourceListRoute(resource);
  const topCards = [
    <DetailGrid
      key={-1}
      title={
        <Title onDelete={canDelete && handleDelete} toEdit={toEdit}>
          <BackTo to={backToVal} />
          {title(state)}
        </Title>
      }
      properties={properties(state, replaceState)}
    />,
  ];
  const bottomComponents = [];
  if (children) {
    React.Children.forEach(children(state, replaceState), (c, i) => {
      if (!c) {
        return;
      }
      if (
        c.type.name === resourceSummaryTypeName ||
        c.type.name === detailGridTypeName ||
        c.props.isDetailGrid
      ) {
        topCards.push(<React.Fragment key={i}>{React.cloneElement(c)}</React.Fragment>);
      } else {
        bottomComponents.push(
          <React.Fragment key={i}>{React.cloneElement(c)}</React.Fragment>
        );
      }
    });
  }

  return (
    <Stack key={rerenderKey} gap={3}>
      <Box sx={{ display: "flex", flexWrap: "wrap", gap: 2 }}>{topCards}</Box>
      {bottomComponents}
    </Stack>
  );
}

function Title({ toEdit, onDelete, children }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const deleteDialogToggle = useToggle();
  const [deleting, setDeleting] = React.useState(false);
  const handleDelete = React.useCallback(
    (e) => {
      e.preventDefault();
      setDeleting(true);
      onDelete().catch((e) => {
        enqueueErrorSnackbar(e);
        setDeleting(false);
        deleteDialogToggle.turnOff();
      });
    },
    [deleteDialogToggle, enqueueErrorSnackbar, onDelete]
  );

  return (
    <>
      {children}
      {toEdit && (
        <IconButton to={toEdit} component={AdminLink}>
          <EditIcon color="info" />
        </IconButton>
      )}
      {onDelete && deleting && <CircularProgress />}
      {onDelete && !deleting && (
        <>
          <IconButton onClick={deleteDialogToggle.turnOn}>
            <DeleteIcon color="error" />
          </IconButton>
          <Dialog open={deleteDialogToggle.isOn} onClose={deleteDialogToggle.turnOff}>
            <DialogTitle>Destroy this resource?</DialogTitle>
            <DialogContent>
              <DialogContentText>
                Do you want to destroy this resource in the database? This operation
                cannot be undone.
              </DialogContentText>
            </DialogContent>
            <DialogActions>
              <Button onClick={deleteDialogToggle.turnOff}>Cancel</Button>
              <Button variant="contained" color="error" onClick={handleDelete}>
                Delete
              </Button>
            </DialogActions>
          </Dialog>
        </>
      )}
    </>
  );
}

export function ResourceSummary({ children }) {
  return children;
}

const resourceSummaryTypeName = (<ResourceSummary />).type.name;
const detailGridTypeName = (<DetailGrid properties={[]} />).type.name;
