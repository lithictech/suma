import useRoleAccess from "../hooks/useRoleAccess";
import CancelIcon from "@mui/icons-material/Cancel";
import EditIcon from "@mui/icons-material/Edit";
import HourglassTopIcon from "@mui/icons-material/HourglassTop";
import SaveIcon from "@mui/icons-material/Save";
import IconButton from "@mui/material/IconButton";
import React from "react";

/**
 * Inline editing component that wraps display and edit states.
 * 'display' rendering gets an Edit icon.
 * 'edit' rendering gets Save and Cancel icons.
 *
 * @param resource Resource type, like 'member'.
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
  resource,
  renderDisplay,
  renderEdit,
  initialEditingState,
  onSave,
}) {
  const { canWriteResource } = useRoleAccess();
  const [editing, setEditing] = React.useState(false);
  const [editingState, setEditingState] = React.useState(initialEditingState);
  const [saving, setSaving] = React.useState(false);
  // Set when leaving edit mode, so focus returns to the Edit button.
  const [restoreFocus, setRestoreFocus] = React.useState(false);
  const editButtonRef = React.useRef(null);
  const editContainerRef = React.useRef(null);

  React.useEffect(() => {
    if (editing) {
      // Move focus into the edit control when editing starts.
      const el = editContainerRef.current?.querySelector(
        "input, textarea, select, [tabindex]:not([tabindex='-1'])"
      );
      el?.focus();
    } else if (restoreFocus) {
      editButtonRef.current?.focus();
      setRestoreFocus(false);
    }
  }, [editing, restoreFocus]);

  function startEditing(e) {
    setEditing(true);
    setSaving(false);
    setEditingState(initialEditingState);
  }
  async function saveChanges(e) {
    setSaving(true);
    try {
      await onSave(editingState);
      setEditing(false);
      setRestoreFocus(true);
    } finally {
      setSaving(false);
    }
  }
  function discardChanges(e) {
    setEditing(false);
    setRestoreFocus(true);
    setEditingState(initialEditingState); // Not strictly needed
  }
  if (!canWriteResource(resource)) {
    return <div>{renderDisplay}</div>;
  }
  if (!editing) {
    return (
      <div>
        {renderDisplay}
        <IconButton ref={editButtonRef} aria-label="Edit" onClick={startEditing}>
          <EditIcon color="info" />
        </IconButton>
      </div>
    );
  }
  return (
    <div ref={editContainerRef}>
      {renderEdit(editingState, setEditingState)}
      <IconButton disabled aria-label="Saving" sx={{ display: saving ? null : "none" }}>
        <HourglassTopIcon />
      </IconButton>
      <IconButton
        aria-label="Save"
        sx={{ display: saving ? "none" : null }}
        onClick={saveChanges}
      >
        <SaveIcon color="success" />
      </IconButton>
      <IconButton
        aria-label="Cancel"
        sx={{ display: saving ? "none" : null }}
        onClick={discardChanges}
      >
        <CancelIcon color="error" />
      </IconButton>
    </div>
  );
}
