import { dayjs } from "../modules/dayConfig";
import AdminLink from "./AdminLink";
import has from "lodash/has";
import React from "react";

export default function resourceDetailCommonFields(model) {
  const result = [];
  if (model.id) {
    result.push({ label: "ID", value: model.id });
  }
  if (model.createdAt) {
    result.push({ label: "Created At", value: dayjs(model.createdAt) });
  }
  if (has(model, "updatedAt")) {
    const value = model.updatedAt ? dayjs(model.updatedAt) : "-";
    result.push({ label: "Updated At", value });
  }
  if (has(model, "createdBy")) {
    const value = model.createdBy ? (
      <AdminLink model={model.createdBy}>{model.createdBy.name}</AdminLink>
    ) : (
      "-"
    );
    result.push({ label: "Created By", value });
  }
  if (has(model, "softDeletedAt")) {
    const value = model.softDeletedAt ? dayjs(model.softDeletedAt) : "";
    result.push({ label: "Deleted At", value });
  }
  return result;
}
