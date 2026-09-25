import { t } from "../localization";
import React from "react";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";

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
          aria-label={t("common.cancel")}
          onClick={onCancel}
        >
          <i className="bi bi-x-lg" aria-hidden="true"></i>
        </Button>
        <Button
          variant="success"
          className="h-100 fs-6 fw-bolder"
          type="submit"
          size="sm"
          disabled={saveDisabled}
          aria-label={t("forms.save")}
          onClick={onSave}
        >
          <i className="bi bi-check-lg" aria-hidden="true"></i>
        </Button>
      </Stack>
    </div>
  );
}
