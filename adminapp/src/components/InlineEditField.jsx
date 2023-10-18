import CancelIcon from "@mui/icons-material/Cancel";
import EditIcon from "@mui/icons-material/Edit";
import SaveIcon from "@mui/icons-material/Save";
import IconButton from "@mui/material/IconButton";
import React from "react";

/**
 * Inline editing component that wraps display and edit states.
 * 'display' rendering gets an Edit icon.
 * 'edit' rendering gets Save and Cancel icons.
 *
 * @param renderDisplay Value to be used when not in editing mode. An Edit icon is added to the right.
 * @param renderEdit Function to be called with (editingState, setEditingState) when in edit mode.
 *   This usually renders an Input that calls setEditingState when it changes.
 * @param initialEditingState Value to use as the initial editing state.
 *   This is usually an empty object (or one with just an id).
 * @param onSave Called with the current editing state
 *   (initialEditingState, then any changes from setEditingState in the renderEdit callback)
 *   when the save button is pressed.
 */
export default function InlineEditField({
  renderDisplay,
  renderEdit,
  initialEditingState,
  onSave,
}) {
  const [editing, setEditing] = React.useState(false);
  const [editingState, setEditingState] = React.useState(initialEditingState);
  function startEditing(e) {
    setEditing(true);
    setEditingState(initialEditingState);
  }
  async function saveChanges(e) {
    await onSave(editingState);
    setEditing(false);
  }
  function discardChanges(e) {
    setEditing(false);
    setEditingState(initialEditingState); // Not strictly needed
  }
  if (!editing) {
    return (
      <div>
        {renderDisplay}
        <IconButton onClick={startEditing}>
          <EditIcon color="info" />
        </IconButton>
      </div>
    );
  }
  return (
    <div>
      {renderEdit(editingState, setEditingState)}
      <IconButton onClick={saveChanges}>
        <SaveIcon color="success" />
      </IconButton>
      <IconButton onClick={discardChanges}>
        <CancelIcon color="error" />
      </IconButton>
    </div>
  );
}
