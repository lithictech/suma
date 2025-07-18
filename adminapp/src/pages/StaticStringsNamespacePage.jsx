import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import DeleteIcon from "@mui/icons-material/Delete";
import FormatColorTextIcon from "@mui/icons-material/FormatColorText";
import RestoreFromTrashIcon from "@mui/icons-material/RestoreFromTrash";
import { CircularProgress, Typography } from "@mui/material";
import { makeStyles } from "@mui/styles";
import { DataGrid, GridActionsCellItem, GridCellEditStopReasons } from "@mui/x-data-grid";
import startCase from "lodash/startCase";
import React from "react";
import { useParams } from "react-router-dom";

export default function StaticStringsNamespacePage() {
  const { namespace } = useParams();
  const { state, loading } = useAsyncFetch(api.getStaticStrings, {
    default: { items: [] },
    pickData: true,
  });
  if (loading) {
    return <CircularProgress />;
  }
  const staticStrings = state.items.find((o) => o.namespace === namespace);
  if (!staticStrings) {
    return <div>Invalid static strings namespace: {namespace}</div>;
  }
  const strings = staticStrings.strings;
  return (
    <>
      <Typography variant="h5" gutterBottom>
        &lsquo;{startCase(namespace)}&rsquo; Static Strings
      </Typography>
      <div style={{ height: HEADER_HEIGHT + strings.length * ROW_HEIGHT }}>
        <StaticStringsTable namespace={namespace} strings={strings} />
      </div>
    </>
  );
}

function StaticStringsTable({ strings }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const classes = useStyles();
  const [updatedStringsById, setUpdatedStringsById] = React.useState({});

  const combinedStrings = strings.map((s) => updatedStringsById[s.id] || s);

  const handleApiCall = React.useCallback(
    (promise) => {
      promise
        .then((r) => {
          setUpdatedStringsById({ ...updatedStringsById, [r.data.id]: r.data });
        })
        .catch(enqueueErrorSnackbar);
    },
    [enqueueErrorSnackbar, updatedStringsById]
  );
  const handleDeleteClick = React.useCallback(
    (row) => {
      handleApiCall(api.deprecateStaticString({ id: row.id }));
    },
    [handleApiCall]
  );

  const handleRestoreClick = React.useCallback(
    (row) => {
      handleApiCall(api.undeprecatedStaticString({ id: row.id }));
    },
    [handleApiCall]
  );
  const handleEditClick = React.useCallback(() => {}, []);
  const handleCellEditStop = React.useCallback(
    (params, event) => {
      if (params.reason === GridCellEditStopReasons.cellFocusOut) {
        event.defaultMuiPrevented = true;
        return;
      }
      handleApiCall(
        api.updateStaticString({
          id: params.row.id,
          [params.colDef.field]: event.target.value,
        })
      );
    },
    [handleApiCall]
  );

  const columns = React.useMemo(
    () => [
      { field: "key", headerName: "Key", width: 250 },
      { field: "en", headerName: "English", editable: true, flex: 1 },
      { field: "es", headerName: "Spanish", editable: true, flex: 1 },
      {
        field: "actions",
        type: "actions",
        headerName: "Actions",
        width: 100,
        getActions: ({ row }) => {
          return [
            <GridActionsCellItem
              icon={<FormatColorTextIcon />}
              label="Edit"
              onClick={() => handleEditClick()}
              color="inherit"
            />,
            row.deprecated ? (
              <GridActionsCellItem
                icon={<RestoreFromTrashIcon />}
                label="Restore"
                onClick={() => handleRestoreClick(row)}
                color="inherit"
              />
            ) : (
              <GridActionsCellItem
                icon={<DeleteIcon />}
                label="Delete"
                onClick={() => handleDeleteClick(row)}
                color="inherit"
              />
            ),
          ];
        },
      },
    ],
    [handleDeleteClick, handleEditClick, handleRestoreClick]
  );

  const getRowClassName = React.useCallback(
    (params) => {
      if (params.row.deprecated) {
        return classes.deprecatedRow;
      } else if (params.row.needsText) {
        return classes.needsTextRow;
      }
    },
    [classes.deprecatedRow, classes.needsTextRow]
  );

  return (
    <DataGrid
      experimentalFeatures={{ newEditingApi: true }}
      classes={{ footerContainer: classes.footerContainer }}
      columns={columns}
      rows={combinedStrings}
      onCellEditStop={handleCellEditStop}
      getRowClassName={getRowClassName}
    />
  );
}

const HEADER_HEIGHT = 56;
const ROW_HEIGHT = 52;

const useStyles = makeStyles(() => ({
  deprecatedRow: {
    opacity: 0.3,
  },
  needsTextRow: {
    backgroundColor: "rgb(255, 244, 244)",
  },
  footerContainer: {
    display: "none !important",
  },
}));
