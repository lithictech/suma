import api from "../api";
import BackToList from "../components/BackToList";
import FabAdd from "../components/FabAdd";
import Link from "../components/Link";
import ResponsiveStack from "../components/ResponsiveStack";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import extractErrorMessage from "../modules/extractErrorMessage";
import { resourceCreateRoute } from "../modules/resourceRoutes";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import CloseIcon from "@mui/icons-material/Close";
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
import IconButton from "@mui/material/IconButton";
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

  const docsToggle = useToggle();
  const modalToggle = useToggle();
  const modalSaving = useToggle();
  const [rowBeingEdited, setRowBeingEdited] = React.useState({});

  const handleSavePromise = React.useCallback(
    (row, promise) =>
      promise
        .then((r) =>
          setUpdatedStringsById({ ...updatedStringsById, [r.data.id]: r.data })
        )
        .tapCatch((e) => enqueueErrorSnackbar(`${row.key}: ${extractErrorMessage(e)}`)),
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
        <BackToList to="/static-strings" />
        &lsquo;{startCase(namespace)}&rsquo; Static Strings{" "}
        <Button sx={{ ml: 2 }} onClick={docsToggle.toggle}>
          Help
        </Button>
      </Typography>
      <DocsModal toggle={docsToggle} selectedRow={rowBeingEdited} />
      <StaticStringsDialog
        toggle={modalToggle}
        docsToggle={docsToggle}
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

function StaticStringsDialog({
  toggle,
  saving,
  row,
  docsToggle,
  onFieldChange,
  onSavePromise,
}) {
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
      fullWidth
      maxWidth="lg"
      PaperProps={{
        component: "form",
        onSubmit: handleModalSubmit,
      }}
      onClose={handleModalClose}
    >
      <DialogTitle sx={{ lineBreak: "anywhere" }}>
        Edit {row.namespace}:{row.key}
        <Button sx={{ ml: 2 }} onClick={docsToggle.toggle}>
          Help
        </Button>
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

function DocsModal({ toggle, selectedRow }) {
  return (
    <Dialog onClose={toggle.turnOff} open={toggle.isOn}>
      <DialogTitle>Static Strings Help</DialogTitle>
      <IconButton
        onClick={toggle.turnOff}
        sx={{
          position: "absolute",
          right: 8,
          top: 8,
          color: (theme) => theme.palette.grey[500],
        }}
      >
        <CloseIcon />
      </IconButton>
      <DialogContent>
        <DialogContentText>
          Static strings are not tied to specific pieces of content, like program
          descriptions. They are usually referred to directly in the UI (like form
          labels), or their keys are referred to by dynamic content (like how offerings
          have a field for their confirmation email template).
        </DialogContentText>
        <DialogContentText sx={{ mt: 2 }}>
          <strong>Formatting:</strong> Strings can use Markdown formatting, usually{" "}
          <strong>**two asterisks bold**</strong> or <em>*one asterisk for italic*</em>.
        </DialogContentText>
        <DialogContentText sx={{ mt: 2 }}>
          <strong>Finding strings:</strong> You can view string keys in the app by adding{" "}
          <strong style={{ whiteSpace: "nowrap" }}>"?debugstaticstrings=1"</strong> to any
          URL in the web app.
        </DialogContentText>
        <DialogContentText sx={{ mt: 2 }}>
          <strong>Interpolation:</strong> Strings often must <em>interpolate</em> dynamic
          values. For example, a string like{" "}
          <strong>"There are &#123;&#123; value &#125;&#125; people here"</strong> will
          render on the frontend as <strong>"There are 5 people here"</strong>.
          Programmers will include the necessary dynamic values in the strings they stub
          out.
        </DialogContentText>
        <DialogContentText sx={{ mt: 2 }}>
          <strong>References:</strong>{" "}
          {selectedRow.key ? (
            <>
              Strings can also <em>refer</em> to other strings. For example,{" "}
              <strong>
                "Hello $(
                {selectedRow.namespace || "strings"}.${selectedRow.key})"
              </strong>{" "}
              would render the string <strong>"Hello {selectedRow.en}"</strong>
            </>
          ) : (
            <>
              Strings can also <em>refer</em> to other strings. For example,{" "}
              <strong>"Reach us at $(strings.common.suma_help_email)"</strong> would
              render a link to our help email.
            </>
          )}
        </DialogContentText>
      </DialogContent>
    </Dialog>
  );
}
