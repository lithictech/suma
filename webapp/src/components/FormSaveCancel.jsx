import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";

export default function FormSaveCancel({
  saveDisabled,
  className,
  style,
  onSave,
  onCancel,
}) {
  return (
    <div className={className} style={style}>
      <Stack gap={2} direction="horizontal" className="justify-content-center">
        <Button
          variant="danger"
          className="h-100 fs-6 fw-bolder"
          size="sm"
          onClick={onCancel}
        >
          <i className="bi bi-x-lg"></i>
        </Button>
        <Button
          variant="success"
          className="h-100 fs-6 fw-bolder"
          type="submit"
          size="sm"
          disabled={saveDisabled}
          onClick={onSave}
        >
          <i className="bi bi-check-lg"></i>
        </Button>
      </Stack>
    </div>
  );
}
