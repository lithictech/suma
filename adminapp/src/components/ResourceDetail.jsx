import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import { resourceEditRoute, resourceListRoute } from "../modules/resourceRoutes";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import DetailGrid from "./DetailGrid";
import Link from "./Link";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import {
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from "@mui/material";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";
import isEmpty from "lodash/isEmpty";
import isFunction from "lodash/isFunction";
import startCase from "lodash/startCase";
import React from "react";
import { useNavigate, useParams } from "react-router-dom";

export default function ResourceDetail({
  resource,
  apiDelete,
  apiGet,
  title,
  properties,
  canEdit,
  children,
}) {
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
                onDelete={
                  apiDelete &&
                  (() =>
                    apiDelete({ id }).then(() => navigate(resourceListRoute(resource))))
                }
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
        <IconButton href={toEdit} component={Link}>
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
