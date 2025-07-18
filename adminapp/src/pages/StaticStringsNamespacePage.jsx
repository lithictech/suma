import api from "../api";
import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResponsiveStack from "../components/ResponsiveStack";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import extractErrorMessage from "../modules/extractErrorMessage";
import { resourceCreateRoute } from "../modules/resourceRoutes";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import DeleteIcon from "@mui/icons-material/Delete";
import FormatColorTextIcon from "@mui/icons-material/FormatColorText";
import RestoreFromTrashIcon from "@mui/icons-material/RestoreFromTrash";
import LoadingButton from "@mui/lab/LoadingButton";
import {
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
  Typography,
} from "@mui/material";
import { makeStyles } from "@mui/styles";
import { DataGrid, GridActionsCellItem, GridCellEditStopReasons } from "@mui/x-data-grid";
import startCase from "lodash/startCase";
import React from "react";
import { useParams } from "react-router-dom";

export default function StaticStringsNamespacePage() {
  const { namespace } = useParams();
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { state, loading } = useAsyncFetch(api.getStaticStrings, {
    default: { items: [] },
    pickData: true,
  });
  const namespaceStrings = React.useMemo(() => {
    const group = state.items.find((o) => o.namespace === namespace);
    return group ? group.strings : [];
  }, [namespace, state.items]);
  const [updatedStringsById, setUpdatedStringsById] = React.useState({});
  const combinedStrings = React.useMemo(
    () => namespaceStrings.map((s) => updatedStringsById[s.id] || s),
    [namespaceStrings, updatedStringsById]
  );

  const modalToggle = useToggle();
  const modalSaving = useToggle();
  const [rowBeingEdited, setRowBeingEdited] = React.useState({});

  const handleSavePromise = React.useCallback(
    (row, promise) =>
      promise
        .then((r) =>
          setUpdatedStringsById({ ...updatedStringsById, [r.data.id]: r.data })
        )
        .tapCatch((e) =>
          enqueueErrorSnackbar(`${row.key}: ${extractErrorMessage(e)}`, null)
        ),
    [enqueueErrorSnackbar, updatedStringsById]
  );

  const handleRowEdit = React.useCallback(
    (row) => {
      modalSaving.turnOff();
      modalToggle.turnOn();
      setRowBeingEdited(row);
    },
    [modalSaving, modalToggle]
  );

  const handleRowFieldChange = React.useCallback(
    (field, value) => {
      setRowBeingEdited({ ...rowBeingEdited, [field]: value });
    },
    [rowBeingEdited]
  );

  if (loading) {
    return <CircularProgress />;
  }
  if (!namespaceStrings) {
    return <div>Invalid static strings namespace: {namespace}</div>;
  }
  return (
    <>
      <Typography variant="h5" gutterBottom>
        &lsquo;{startCase(namespace)}&rsquo; Static Strings
      </Typography>
      <StaticStringsDialog
        toggle={modalToggle}
        saving={modalSaving}
        row={rowBeingEdited}
        onFieldChange={handleRowFieldChange}
        onSavePromise={handleSavePromise}
      />
      <div style={{ height: HEADER_HEIGHT + combinedStrings.length * ROW_HEIGHT }}>
        <StaticStringsTable
          namespace={namespace}
          strings={combinedStrings}
          onRowEdit={handleRowEdit}
          onSavePromise={handleSavePromise}
        />
      </div>
      <FabAdd
        component={Link}
        href={resourceCreateRoute("static_string") + `?namespace=${namespace}`}
      />
    </>
  );
}

function StaticStringsTable({ strings, onRowEdit, onSavePromise }) {
  const classes = useStyles();

  const handleDeleteClick = React.useCallback(
    (row) => {
      onSavePromise(row, api.deprecateStaticString({ id: row.id }));
    },
    [onSavePromise]
  );

  const handleRestoreClick = React.useCallback(
    (row) => {
      onSavePromise(row, api.undeprecatedStaticString({ id: row.id }));
    },
    [onSavePromise]
  );
  const handleEditClick = React.useCallback((row) => onRowEdit(row), [onRowEdit]);
  const handleCellEditStop = React.useCallback(
    (params, event) => {
      if (params.reason === GridCellEditStopReasons.cellFocusOut) {
        event.defaultMuiPrevented = true;
        return;
      } else if (params.reason === GridCellEditStopReasons.escapeKeyDown) {
        return;
      }
      onSavePromise(
        params.row,
        api.updateStaticString({
          id: params.row.id,
          [params.colDef.field]: event.target.value,
        })
      );
    },
    [onSavePromise]
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
              onClick={() => handleEditClick(row)}
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
      rows={strings}
      getRowClassName={getRowClassName}
      onCellEditStop={handleCellEditStop}
    />
  );
}

function StaticStringsDialog({ toggle, saving, row, onFieldChange, onSavePromise }) {
  const handleModalClose = React.useCallback(() => {
    // Don't set these here, or it causes modal flashing before it disappears.
    // setRowBeingEdited({});
    // saving.turnOff();
    toggle.turnOff();
  }, [toggle]);

  const handleModalSubmit = React.useCallback(
    (event) => {
      event.preventDefault();
      saving.turnOn();
      onSavePromise(
        row,
        api.updateStaticString({
          id: row.id,
          en: row.en,
          es: row.es,
        })
      )
        .tapCatch(saving.turnOff)
        .then(handleModalClose);
    },
    [saving, onSavePromise, row, handleModalClose]
  );

  return (
    <Dialog
      open={toggle.isOn}
      disableEscapeKeyDown
      maxWidth="lg"
      PaperProps={{
        component: "form",
        onSubmit: handleModalSubmit,
      }}
      onClose={handleModalClose}
    >
      <DialogTitle sx={{ lineBreak: "anywhere" }}>
        Edit {row.namespace}:{row.key}
      </DialogTitle>
      <DialogContent>
        <ResponsiveStack rowAt="md" sx={{ pt: 1 }}>
          <TextField
            autoFocus
            margin="dense"
            name="en"
            label="English"
            fullWidth
            multiline
            rows={5}
            variant="outlined"
            value={row.en || ""}
            onChange={(e) => onFieldChange("en", e.target.value)}
          />
          <TextField
            margin="dense"
            name="es"
            label="Spanish"
            fullWidth
            multiline
            rows={5}
            variant="outlined"
            value={row.es || ""}
            onChange={(e) => onFieldChange("es", e.target.value)}
          />
        </ResponsiveStack>
        <DialogContentText sx={{ mt: 2 }}>
          Strings can use Markdown formatting, usually{" "}
          <strong>**two asterisks bold**</strong> or <em>*one asterisk for italic*</em>.
        </DialogContentText>
        <DialogContentText sx={{ mt: 2 }}>
          Strings often must <em>interpolate</em> dynamic values. For example, a string
          like <strong>There are &#123;&#123; value &#125;&#125; people here</strong> will
          render on the frontend as <strong>There are 5 people here</strong>. Usually
          programmers will include the necessary dynamic values in the strings they stub
          out. Translators aren't expected to work with this feature.
        </DialogContentText>
        <DialogContentText sx={{ mt: 2 }}>
          Strings can also refer to other strings. For example,{" "}
          <strong>
            Hello $(
            {row.namespace}.${row.key})
          </strong>{" "}
          would render the string <strong>Hello {row.en}</strong>
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleModalClose}>Cancel</Button>
        <LoadingButton type="submit" variant="contained" loading={saving.isOn}>
          Save
        </LoadingButton>
      </DialogActions>
    </Dialog>
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
