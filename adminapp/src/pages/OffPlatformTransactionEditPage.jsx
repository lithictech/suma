import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import OffPlatformTransactionInputs from "./OffPlatformTransactionInputs";
import { Stack } from "@mui/material";
import startCase from "lodash/startCase";
import React from "react";

export default function OffPlatformTransactionEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getOffPlatformTransaction}
      apiUpdate={api.updateOffPlatformTransaction}
      Form={Form}
    />
  );
}

function Form({ resource, setField, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title={`Edit Off Platform ${startCase(resource.type)}`}
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack gap={2}>
        <OffPlatformTransactionInputs
          register={register}
          resource={resource}
          setField={setField}
          setFieldFromInput={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
